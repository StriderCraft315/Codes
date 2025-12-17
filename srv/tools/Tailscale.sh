#!/bin/bash

# Colors for better UI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'
DIM='\033[2m'

# Function to display header
display_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}${BOLD}                TAILSCALE MANAGEMENT PANEL                ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Function to display status
check_tailscale_status() {
    if command -v tailscale &> /dev/null; then
        if systemctl is-active --quiet tailscaled; then
            echo -e "${GREEN}✓ Tailscale: ${BOLD}Installed & Running${NC}"
            echo -e "${DIM}  IP: $(tailscale ip 2>/dev/null || echo 'Not connected')${NC}"
        else
            echo -e "${YELLOW}⚠ Tailscale: ${BOLD}Installed but Stopped${NC}"
        fi
    else
        echo -e "${RED}✗ Tailscale: ${BOLD}Not Installed${NC}"
    fi
}

# Function to install Tailscale
install_tailscale() {
    echo -e "\n${BLUE}${BOLD}[1/3] 📥 Downloading and installing Tailscale...${NC}"
    echo -e "${DIM}This will add Tailscale's repository and install the package${NC}"
    echo ""
    
    if curl -fsSL https://tailscale.com/install.sh | sh; then
        echo -e "\n${GREEN}${BOLD}✓ Tailscale installed successfully!${NC}"
    else
        echo -e "\n${RED}${BOLD}✗ Installation failed!${NC}"
        return 1
    fi
    
    echo -e "\n${BLUE}${BOLD}[2/3] 🔗 Starting Tailscale service...${NC}"
    sudo systemctl enable --now tailscaled
    
    echo -e "\n${BLUE}${BOLD}[3/3] 🚀 Connecting to Tailscale network...${NC}"
    echo -e "${YELLOW}Please authenticate in your browser when prompted${NC}"
    echo ""
    sudo tailscale up
    
    echo -e "\n${GREEN}${BOLD}══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}✅ Installation complete! Tailscale is now active.${NC}"
    echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════${NC}"
}

# Function to uninstall Tailscale
uninstall_tailscale() {
    echo -e "\n${RED}${BOLD}⚠ ══════════════════════════════════════════════════ ═${NC}"
    echo -e "${RED}${BOLD}        TAILSCALE COMPLETE REMOVAL${NC}"
    echo -e "${RED}${BOLD}⚠ ══════════════════════════════════════════════════ ═${NC}"
    echo -e "${YELLOW}This will remove Tailscale and all its data${NC}"
    echo ""
    
    read -p "Are you sure? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}Cancelled. Tailscale was NOT removed.${NC}"
        return
    fi
    
    echo -e "\n${RED}[1/4] 🛑 Stopping Tailscale service...${NC}"
    sudo systemctl stop tailscaled
    sudo systemctl disable tailscaled
    
    echo -e "${RED}[2/4] 🗑️ Removing Tailscale package...${NC}"
    sudo apt purge tailscale -y
    
    echo -e "${RED}[3/4] 🧹 Cleaning up residual files...${NC}"
    sudo rm -rf /var/lib/tailscale /etc/tailscale /var/cache/tailscale
    
    echo -e "${RED}[4/4] 🧽 Removing unused dependencies...${NC}"
    sudo apt autoremove -y
    
    echo -e "\n${GREEN}${BOLD}══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}✅ Tailscale completely removed from system!${NC}"
    echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════${NC}"
}

# Function to view Tailscale status
view_status() {
    echo -e "\n${BLUE}${BOLD}📊 TAILSCALE STATUS${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════${NC}"
    
    if command -v tailscale &> /dev/null; then
        echo -e "${CYAN}Service Status:${NC}"
        systemctl status tailscaled --no-pager -l | head -20
        
        echo -e "\n${CYAN}Network Status:${NC}"
        tailscale status 2>/dev/null || echo -e "${YELLOW}Not connected to network${NC}"
        
        echo -e "\n${CYAN}IP Addresses:${NC}"
        tailscale ip 2>/dev/null || echo -e "${YELLOW}No IP assigned${NC}"
    else
        echo -e "${RED}Tailscale is not installed${NC}"
    fi
}

# Function to restart Tailscale
restart_tailscale() {
    echo -e "\n${YELLOW}${BOLD}🔄 Restarting Tailscale service...${NC}"
    sudo systemctl restart tailscaled
    echo -e "${GREEN}${BOLD}✓ Tailscale service restarted!${NC}"
    
    # Wait a moment and show status
    sleep 2
    echo -e "\n${CYAN}Current status:${NC}"
    systemctl is-active tailscaled && echo -e "${GREEN}Active${NC}" || echo -e "${RED}Inactive${NC}"
}

# Function to connect/disconnect
toggle_connection() {
    if tailscale status &>/dev/null; then
        echo -e "\n${YELLOW}${BOLD}Disconnecting from Tailscale network...${NC}"
        sudo tailscale down
        echo -e "${GREEN}${BOLD}✓ Disconnected from Tailscale network${NC}"
    else
        echo -e "\n${BLUE}${BOLD}Connecting to Tailscale network...${NC}"
        sudo tailscale up
        echo -e "${GREEN}${BOLD}✓ Connected to Tailscale network${NC}"
    fi
}

# Function to display menu
display_menu() {
    echo -e "${BOLD}📋 Available Options:${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════${NC}"
    echo -e "  ${GREEN}[1]${NC} ${BOLD}📥 Install Tailscale${NC}"
    echo -e "  ${RED}[2]${NC} ${BOLD}🗑️  Uninstall Tailscale${NC}"
    echo -e "  ${CYAN}[3]${NC} ${BOLD}📊 View Status${NC}"
    echo -e "  ${YELLOW}[4]${NC} ${BOLD}🔄 Restart Service${NC}"
    echo -e "  ${MAGENTA}[5]${NC} ${BOLD}🔗 Connect/Disconnect${NC}"
    echo -e "  ${DIM}[6]${NC} ${BOLD}ℹ️  View this machine's info${NC}"
    echo -e "  ${RED}[0]${NC} ${BOLD}🚪 Exit${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════${NC}"
}

# Function to show machine info
show_machine_info() {
    echo -e "\n${CYAN}${BOLD}🖥️  SYSTEM INFORMATION${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}Hostname:${NC} $(hostname)"
    echo -e "${BOLD}Distribution:${NC} $(lsb_release -d 2>/dev/null | cut -f2 || cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '\"')"
    echo -e "${BOLD}Kernel:${NC} $(uname -r)"
    echo -e "${BOLD}Architecture:${NC} $(uname -m)"
    
    if command -v tailscale &> /dev/null; then
        echo -e "\n${BOLD}Tailscale Version:${NC} $(tailscale version | head -1)"
    fi
}

# Main loop
while true; do
    display_header
    check_tailscale_status
    echo ""
    display_menu
    
    echo ""
    read -p "$(echo -e ${BOLD}'Choose option [0-6]: '${NC})" option
    
    case $option in
        1)
            install_tailscale
            ;;
        2)
            uninstall_tailscale
            ;;
        3)
            view_status
            ;;
        4)
            restart_tailscale
            ;;
        5)
            toggle_connection
            ;;
        6)
            show_machine_info
            ;;
        0)
            echo -e "\n${CYAN}${BOLD}👋 Goodbye! Thank you for using Tailscale Manager${NC}"
            echo -e "${DIM}Script terminated.${NC}\n"
            exit 0
            ;;
        *)
            echo -e "\n${RED}${BOLD}✗ Invalid option! Please choose between 0 and 6${NC}"
            ;;
    esac
    
    echo ""
    echo -e "${DIM}══════════════════════════════════════════════════${NC}"
    read -p "$(echo -e ${DIM}'Press Enter to continue...'${NC})" dummy
done
