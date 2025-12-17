#!/bin/bash

# Colors
R="\e[31m"; G="\e[32m"; Y="\e[33m"
B="\e[34m"; M="\e[35m"; C="\e[36m"
W="\e[97m"; N="\e[0m"

clear_ui() { clear; }

header() {
clear_ui
echo -e "${M}╔══════════════════════════════════════╗${N}"
echo -e "${M}║${W}     🚀 RDP + noVNC CONTROL PANEL     ${M}║${N}"
echo -e "${M}╠══════════════════════════════════════╣${N}"
echo -e "${M}║${C}  XFCE • xRDP • Browser Desktop       ${M}║${N}"
echo -e "${M}╚══════════════════════════════════════╝${N}"
echo
}

install_all() {
echo -e "${Y}Installing Desktop + RDP + noVNC...${N}"
apt update && apt upgrade -y
apt install xfce4 xfce4-goodies xrdp tigervnc-standalone-server tigervnc-common novnc websockify -y
systemctl enable xrdp && systemctl start xrdp
adduser xrdp ssl-cert
echo xfce4-session > ~/.xsession
echo xfce4-session > /etc/skel/.xsession
vncpasswd
vncserver -localhost no :1

cat <<EOF >/etc/systemd/system/novnc.service
[Unit]
Description=noVNC Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/websockify --web=/usr/share/novnc/ 6080 localhost:5901
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable novnc
systemctl start novnc

ufw allow 3389
ufw allow 6080
ufw allow 5901
ufw reload || true

IP=$(curl -s ifconfig.me)
echo -e "${G}DONE!${N}"
echo -e "RDP  : ${W}$IP:3389${N}"
echo -e "noVNC: ${W}http://$IP:6080${N}"
read -p "Press Enter..."
}

start_services() {
systemctl start xrdp novnc
vncserver -localhost no :1 || true
echo -e "${G}Services Started${N}"
sleep 1
}

stop_services() {
systemctl stop xrdp novnc
vncserver -kill :1 || true
echo -e "${R}Services Stopped${N}"
sleep 1
}

status_services() {
systemctl status xrdp --no-pager
systemctl status novnc --no-pager
read -p "Press Enter..."
}

uninstall_all() {
echo -e "${R}Removing EVERYTHING...${N}"
systemctl stop xrdp novnc || true
apt purge xfce4* xrdp tigervnc* novnc websockify -y
rm -rf ~/.vnc /etc/systemd/system/novnc.service
systemctl daemon-reload
echo -e "${G}Clean Uninstall Done${N}"
read -p "Press Enter..."
}

while true; do
header
echo -e "${C}1) Install RDP + noVNC${N}"
echo -e "${C}2) Start Services${N}"
echo -e "${C}3) Stop Services${N}"
echo -e "${C}4) Status${N}"
echo -e "${C}5) Uninstall All${N}"
echo -e "${R}0) Exit${N}"
echo
read -p "Select option: " opt

case $opt in
1) install_all ;;
2) start_services ;;
3) stop_services ;;
4) status_services ;;
5) uninstall_all ;;
0) exit ;;
*) echo -e "${R}Invalid option${N}"; sleep 1 ;;
esac
done
