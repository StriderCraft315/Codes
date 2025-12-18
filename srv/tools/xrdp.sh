#!/bin/bash

set -e

echo "🚀 XRDP AUTO SETUP STARTING..."

# 1️⃣ Update system
apt update -y && apt upgrade -y

# 2️⃣ Install desktop + xrdp
apt install -y xrdp xfce4 xfce4-goodies dbus-x11

# 3️⃣ Enable services
systemctl enable xrdp
systemctl restart xrdp

# 4️⃣ Set root password = root
echo -e "root\nroot" | passwd root

# 5️⃣ Allow root login in XRDP
sed -i 's/^AllowRootLogin=false/AllowRootLogin=true/' /etc/xrdp/sesman.ini || true

# 6️⃣ Allow root in PAM
sed -i 's/^auth required pam_succeed_if.so user != root quiet_success/#&/' /etc/pam.d/xrdp-sesman || true

# 7️⃣ Set XFCE session for root
echo "startxfce4" > /root/.xsession
chmod +x /root/.xsession

# 8️⃣ Fix permissions
adduser xrdp ssl-cert || true

# 9️⃣ Restart XRDP
systemctl restart xrdp

echo "✅ DONE!"
echo "=============================="
echo "XRDP LOGIN DETAILS:"
echo "IP       : YOUR_VPS_IP"
echo "USERNAME : root"
echo "PASSWORD : root"
echo "SESSION  : Xorg"
echo "=============================="
