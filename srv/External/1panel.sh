# ===================== 1PANEL MENU =====================
onepanel_menu(){
while true; do banner
echo -e "${C_LINE}────────────── 1PANEL MENU ──────────────${NC}"
echo -e "${C_MAIN} 1) Install "
echo -e " 2) Uninstall "
echo -e " 3) Back${NC}"
echo -e "${C_LINE}────────────────────────────────────────${NC}"
read -p "Select → " op

case $op in
1)
  clear
  echo -e "${C_MAIN}🚀 Installing 1Panel (Official Script)...${NC}"
  curl -fsSL https://resource.fit2cloud.com/1panel/package/quick_start.sh | bash
  echo
  echo -e "${C_SEC}✅ 1Panel Installed Successfully${NC}"
  echo -e "${C_SEC}🌐 Access: http://SERVER_IP:10086${NC}"
  pause
;;
2)
  clear
  echo -e "${C_MAIN}🧹 Uninstalling 1Panel (Official)...${NC}"

  if command -v 1pctl >/dev/null 2>&1; then
    1pctl uninstall
    echo
    echo -e "${C_SEC}✅ 1Panel Uninstalled Successfully${NC}"
  else
    echo -e "${RED}❌ 1Panel is not installed or 1pctl not found${NC}"
  fi

  pause
;;
3)
  break
;;
*)
  echo -e "${RED}Invalid Option${NC}"
  pause
;;
esac
done
}
