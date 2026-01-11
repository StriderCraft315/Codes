#!/bin/bash
# FULL AUTO – NEVER EXIT ON ERROR (LOGIN LOOP FIX)
set +e
export DEBIAN_FRONTEND=noninteractive

echo "=== DEBIAN 12 → PROXMOX FULL AUTO RECOVERY + INSTALL ==="

# ---------------- BASIC SAFETY ----------------
if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root"
  exit 1
fi

mount -o remount,rw / || true

# ---------------- STOP APT BACKGROUND ----------------
systemctl stop apt-daily apt-daily-upgrade 2>/dev/null || true

# ---------------- DISK EMERGENCY CLEAN ----------------
echo "[1/14] Disk cleanup..."
rm -rf /var/lib/apt/lists/* \
       /var/cache/apt/* \
       /tmp/* /var/tmp/* || true
apt clean || true
journalctl --vacuum-size=100M || true

# ---------------- NUCLEAR APT RESET ----------------
echo "[2/14] Nuclear reset of APT..."
rm -rf /etc/apt/trusted.gpg
rm -rf /etc/apt/trusted.gpg.d/*
rm -rf /usr/share/keyrings/*
rm -rf /etc/apt/sources.list.d/*
rm -rf /etc/apt/mirrors/*
rm -f  /etc/apt/sources.list

# ---------------- MINIMAL TOOLS ----------------
echo "[3/14] Installing minimal tools..."
apt-get update || true
apt-get install -y ca-certificates curl gnupg wget iproute2 debconf-utils || true

# ---------------- MANUAL DEBIAN KEYS (ALL) ----------------
echo "[4/14] Seeding Debian Bookworm signing keys..."

curl -fsSL https://ftp-master.debian.org/keys/archive-key-12.asc \
 | gpg --dearmor -o /usr/share/keyrings/debian-archive-keyring.gpg

curl -fsSL https://ftp-master.debian.org/keys/archive-key-12-security.asc \
 | gpg --dearmor -o /usr/share/keyrings/debian-security-keyring.gpg

# ---------------- CLEAN SOURCES (NO MIRRORS/BACKPORTS) ----
echo "[5/14] Writing clean Debian sources..."

cat > /etc/apt/sources.list <<EOF
deb [signed-by=/usr/share/keyrings/debian-archive-keyring.gpg] https://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb [signed-by=/usr/share/keyrings/debian-security-keyring.gpg] https://deb.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
deb [signed-by=/usr/share/keyrings/debian-archive-keyring.gpg] https://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
EOF

# ---------------- FINAL APT TEST ----------------
echo "[6/14] Testing APT (must work)..."
apt-get clean
apt-get update
if [ "$?" != "0" ]; then
  echo "❌ APT STILL BROKEN → PROVIDER IMAGE CORRUPT"
  exit 1
fi

# ---------------- HOSTNAME AUTO ----------------
hostname -f >/dev/null 2>&1 || hostnamectl set-hostname proxmox.local

# ---------------- PROXMOX REPO + KEY ----------------
echo "[7/14] Adding Proxmox repository..."
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" \
> /etc/apt/sources.list.d/pve-no-subscription.list

curl -fsSL https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg \
-o /usr/share/keyrings/proxmox-release.gpg

apt-get update

# ---------------- POSTFIX NON-INTERACTIVE ----------------
echo "[8/14] Preconfiguring Postfix..."
echo "postfix postfix/mailname string localhost" | debconf-set-selections
echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections

# ---------------- INSTALL PROXMOX ----------------
echo "[9/14] Installing Proxmox VE..."
dpkg -l | grep -q proxmox-ve || \
apt-get install -y proxmox-ve postfix open-iscsi

# ---------------- REMOVE DEBIAN KERNEL ----------------
echo "[10/14] Removing Debian kernel..."
apt-get remove -y linux-image-amd64 linux-image-cloud-amd64 || true
update-grub

# ---------------- AUTO NETWORK vmbr0 ----------------
echo "[11/14] Auto-detect network..."
IFACE=$(ip route | awk '/default/ {print $5; exit}')
IPCIDR=$(ip -4 addr show "$IFACE" | awk '/inet/ {print $2; exit}')
GATEWAY=$(ip route | awk '/default/ {print $3; exit}')

cat > /etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

auto $IFACE
iface $IFACE inet manual

auto vmbr0
iface vmbr0 inet static
    address $IPCIDR
    gateway $GATEWAY
    bridge-ports $IFACE
    bridge-stp off
    bridge-fd 0
EOF

systemctl restart networking || true
sleep 5

# ---------------- IPV6 DISABLE ----------------
echo "[12/14] Disabling IPv6..."
cat > /etc/sysctl.d/99-disable-ipv6.conf <<EOF
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1
EOF
sysctl --system

# ---------------- SSL AUTO FIX ----------------
echo "[13/14] Fixing Proxmox SSL..."
systemctl stop pveproxy pvedaemon || true
rm -f /etc/pve/local/pve-ssl.* /etc/pve/nodes/*/pve-ssl.*
systemctl restart pve-cluster
sleep 5
pvecm updatecerts --force
systemctl start pvedaemon pveproxy

# ---------------- ENTERPRISE REPO OFF ----------------
sed -i 's|^deb https://enterprise.proxmox.com|# deb https://enterprise.proxmox.com|' \
/etc/apt/sources.list.d/pve-enterprise.list 2>/dev/null || true

# ---------------- DONE ----------------
echo "[14/14] DONE"
pveversion || true
echo "=============================================="
echo "✅ FULL AUTO FIX + PROXMOX INSTALL COMPLETE"
echo "🌐 https://SERVER-IP:8006"
echo "🔁 REBOOT STRONGLY RECOMMENDED"
echo "=============================================="
