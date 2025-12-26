#!/bin/bash

# ============================================
# LXC/LXD Container Manager
# Version: 4.0 - Complete Solution
# ============================================

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# ASCII Art
print_header() {
    clear
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║      ██████╗      ██████╗ ███╗   ██╗███████╗        ║"
    echo "║     ██╔════╝     ██╔════╝ ████╗  ██║██╔════╝        ║"
    echo "║     ██║  ███╗    ██║  ███╗██╔██╗ ██║███████╗        ║"
    echo "║     ██║   ██║    ██║   ██║██║╚██╗██║╚════██║        ║"
    echo "║     ╚██████╔╝    ╚██████╔╝██║ ╚████║███████║        ║"
    echo "║      ╚═════╝      ╚═════╝ ╚═╝  ╚═══╝╚══════╝        ║"
    echo "║                                                    ║"
    echo "║               LXC/LXD CONTAINER MANAGER            ║"
    echo "║               (With OS Selection Menu)             ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Print colored text
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Pause function
pause() {
    echo
    read -p "$(print_color "$CYAN" "⏎ Press Enter to continue...")" dummy
}

# Check if running in container/virtualization
check_virtualization() {
    print_color "$CYAN" "🔍 Checking virtualization environment..."
    
    # Check if systemd-detect-virt exists
    if command -v systemd-detect-virt &> /dev/null; then
        local virt_env=$(systemd-detect-virt)
        
        case $virt_env in
            "none")
                print_color "$GREEN" "✅ Running on bare metal"
                return 0
                ;;
            "kvm"|"qemu"|"vmware"|"virtualbox"|"hyperv"|"xen")
                print_color "$YELLOW" "⚠️  Running in VM: $virt_env"
                print_color "$YELLOW" "   LXC/LXD may work but performance may vary"
                return 0
                ;;
            "lxc"|"lxc-libvirt"|"openvz")
                print_color "$RED" "❌ Running in container: $virt_env"
                print_color "$RED" "   LXC cannot run inside another container"
                return 1
                ;;
            "docker"|"podman"|"rkt")
                print_color "$RED" "❌ Running in container: $virt_env"
                print_color "$RED" "   LXC cannot run inside Docker/Podman"
                return 1
                ;;
            *)
                print_color "$YELLOW" "⚠️  Unknown virtualization: $virt_env"
                print_color "$YELLOW" "   Proceed with caution"
                return 0
                ;;
        esac
    else
        print_color "$YELLOW" "⚠️  systemd-detect-virt not available"
        print_color "$YELLOW" "   Assuming bare metal environment"
        
        # Alternative checks
        if grep -q "container=lxc" /proc/1/environ 2>/dev/null || grep -q "container=docker" /proc/1/environ 2>/dev/null; then
            print_color "$RED" "❌ Running inside a container"
            return 1
        fi
        
        return 0
    fi
}

# Check LXC/LXD installation
check_installation() {
    print_color "$CYAN" "🔍 Checking LXC/LXD installation..."
    
    local checks=0
    local total_checks=4
    
    # Check LXC
    if command -v lxc &> /dev/null; then
        print_color "$GREEN" "✅ LXC is installed"
        ((checks++))
    else
        print_color "$RED" "❌ LXC is NOT installed"
    fi
    
    # Check LXD
    if command -v lxd &> /dev/null || snap list | grep -q lxd; then
        print_color "$GREEN" "✅ LXD is installed"
        ((checks++))
    else
        print_color "$RED" "❌ LXD is NOT installed"
    fi
    
    # Check user in lxd group
    if groups $USER | grep -q lxd; then
        print_color "$GREEN" "✅ User is in lxd group"
        ((checks++))
    else
        print_color "$YELLOW" "⚠️  User is NOT in lxd group"
    fi
    
    # Check LXD service
    if systemctl is-active --quiet snap.lxd.daemon 2>/dev/null || systemctl is-active --quiet lxd 2>/dev/null; then
        print_color "$GREEN" "✅ LXD service is running"
        ((checks++))
    else
        print_color "$RED" "❌ LXD service is NOT running"
    fi
    
    echo
    if [[ $checks -eq $total_checks ]]; then
        print_color "$GREEN" "🎉 LXC/LXD is ready to use!"
        return 0
    elif [[ $checks -ge 2 ]]; then
        print_color "$YELLOW" "⚠️  Some components missing but may work"
        return 0
    else
        print_color "$RED" "🚨 LXC/LXD not properly installed"
        return 1
    fi
}

# Install dependencies
install_dependencies() {
    print_header
    print_color "$CYAN" "🚀 Installing LXC/LXD Dependencies"
    echo "══════════════════════════════════════════════════════"
    
    # Check virtualization
    if ! check_virtualization; then
        print_color "$RED" "❌ Cannot install LXC in virtualized/container environment"
        pause
        return 1
    fi
    
    # Detect OS
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
    else
        print_color "$RED" "❌ Cannot detect OS"
        pause
        return 1
    fi
    
    print_color "$BLUE" "📊 Detected: $PRETTY_NAME"
    
    case $ID in
        ubuntu|debian)
            install_debian
            ;;
        centos|rhel|fedora|rocky|almalinux)
            install_rhel
            ;;
        *)
            print_color "$RED" "❌ Unsupported OS: $ID"
            print_color "$YELLOW" "📋 Please install manually:"
            echo "For Ubuntu/Debian:"
            echo "  sudo apt install lxc lxc-utils bridge-utils snapd"
            echo "  sudo snap install lxd"
            echo "  sudo usermod -aG lxd \$USER"
            echo "  sudo lxd init --auto"
            pause
            return 1
            ;;
    esac
    
    # Post-install
    echo
    print_color "$CYAN" "⚙️  Post-installation setup..."
    
    # Add user to lxd group
    sudo usermod -aG lxd $USER 2>/dev/null
    
    # Initialize LXD
    print_color "$BLUE" "🔧 Initializing LXD..."
    sudo lxd init --auto 2>/dev/null || sudo lxd init
    
    # Start service
    sudo systemctl enable --now snap.lxd.daemon 2>/dev/null || sudo systemctl enable --now lxd
    
    print_color "$GREEN" "✅ Installation complete!"
    print_color "$YELLOW" "⚠️  Please log out and log back in for group changes"
    pause
}

# Install on Debian/Ubuntu
install_debian() {
    print_color "$GREEN" "📦 Installing for Debian/Ubuntu..."
    
    sudo apt update
    sudo apt install -y lxc lxc-utils lxc-templates bridge-utils uidmap
    
    # Install snapd if not present
    if ! command -v snap &> /dev/null; then
        sudo apt install -y snapd
        sudo systemctl enable --now snapd.socket
    fi
    
    # Install LXD via snap
    sudo snap install lxd
}

# Install on RHEL/CentOS/Fedora
install_rhel() {
    print_color "$GREEN" "📦 Installing for RHEL/CentOS/Fedora..."
    
    case $ID in
        fedora)
            sudo dnf install -y lxc lxc-templates lxc-extra bridge-utils
            sudo dnf install -y snapd
            sudo systemctl enable --now snapd.socket
            sudo ln -s /var/lib/snapd/snap /snap
            sudo snap install lxd
            ;;
        centos|rhel|rocky|almalinux)
            if [[ $VERSION_ID == "7" ]]; then
                sudo yum install -y epel-release
                sudo yum install -y lxc lxc-templates bridge-utils
                print_color "$YELLOW" "⚠️  LXD not available for CentOS 7 via package manager"
            else
                sudo dnf install -y epel-release
                sudo dnf install -y lxc lxc-templates lxc-extra bridge-utils
                sudo dnf install -y snapd
                sudo systemctl enable --now snapd.socket
                sudo ln -s /var/lib/snapd/snap /snap
                sudo snap install lxd
            fi
            ;;
    esac
}

# OS Selection Menu
show_os_menu() {
    print_header
    print_color "$CYAN" "📦 Select Operating System"
    echo "══════════════════════════════════════════════════════"
    echo
    
    echo -e "${GREEN}1) Ubuntu 22.04${NC}"
    echo -e "${GREEN}2) Ubuntu 24.04${NC}"
    echo -e "${GREEN}3) Debian 11${NC}"
    echo -e "${GREEN}4) Debian 12${NC}"
    echo -e "${GREEN}5) Debian 13${NC}"
    echo -e "${GREEN}6) AlmaLinux 9${NC}"
    echo -e "${GREEN}7) Rocky Linux 9${NC}"
    echo -e "${GREEN}8) CentOS Stream 9${NC}"
    echo -e "${GREEN}9) Fedora 40${NC}"
    echo -e "${YELLOW}0) ↩️  Back to Main Menu${NC}"
    echo
    
    read -p "$(print_color "$BLUE" "🎯 Select OS (0-9): ")" os
    
    case $os in
        1) img="ubuntu:22.04"; name="Ubuntu 22.04 Jammy" ;;
        2) img="ubuntu:24.04"; name="Ubuntu 24.04 Noble" ;;
        3) img="debian:11"; name="Debian 11 Bullseye" ;;
        4) img="debian:12"; name="Debian 12 Bookworm" ;;
        5) img="debian:13"; name="Debian 13 Trixie" ;;
        6) img="almalinux:9"; name="AlmaLinux 9" ;;
        7) img="rockylinux:9"; name="Rocky Linux 9" ;;
        8) img="centos:stream9"; name="CentOS Stream 9" ;;
        9) img="fedora:40"; name="Fedora 40" ;;
        0) return 1 ;;
        *) 
            print_color "$RED" "❌ Invalid selection"
            pause
            return 1
            ;;
    esac
    
    return 0
}

# Create container
create_container() {
    if ! show_os_menu; then
        return
    fi
    
    print_header
    print_color "$CYAN" "🚀 Creating $name Container"
    echo "══════════════════════════════════════════════════════"
    
    # Get container name
    while true; do
        read -p "$(print_color "$BLUE" "🏷️  Enter container name: ")" container_name
        
        if [[ -z "$container_name" ]]; then
            print_color "$RED" "❌ Container name cannot be empty!"
            continue
        fi
        
        # Check if container exists
        if lxc list -c n --format csv 2>/dev/null | grep -q "^$container_name$"; then
            print_color "$RED" "❌ Container '$container_name' already exists!"
            read -p "Use different name? (y/N): " choice
            if [[ ! "$choice" =~ ^[Yy]$ ]]; then
                return
            fi
            continue
        fi
        
        break
    done
    
    # Container type
    echo
    print_color "$YELLOW" "💻 Container Type:"
    echo "1) Container (lightweight, default)"
    echo "2) Virtual Machine (full VM)"
    read -p "$(print_color "$BLUE" "Select type (1-2, default: 1): ")" vm_choice
    vm_choice=${vm_choice:-1}
    
    local type_flag=""
    if [[ $vm_choice -eq 2 ]]; then
        type_flag="--vm"
        print_color "$GREEN" "✅ Selected: Virtual Machine"
    else
        print_color "$GREEN" "✅ Selected: Container"
    fi
    
    # Resources
    echo
    print_color "$YELLOW" "⚙️  Resource Configuration:"
    read -p "$(print_color "$BLUE" "💾 Disk size (default: 10GB): ")" disk
    disk=${disk:-10GB}
    
    read -p "$(print_color "$BLUE" "🧠 Memory (default: 2GB): ")" memory
    memory=${memory:-2GB}
    
    read -p "$(print_color "$BLUE" "⚡ CPU cores (default: 2): ")" cpu
    cpu=${cpu:-2}
    
    # Summary
    echo
    print_color "$CYAN" "📋 Creation Summary:"
    echo "────────────────────────────"
    echo "🏷️  Name: $container_name"
    echo "📦 OS: $name"
    echo "💻 Type: $([ "$type_flag" == "--vm" ] && echo "VM" || echo "Container")"
    echo "💾 Disk: $disk"
    echo "🧠 Memory: $memory"
    echo "⚡ CPU: $cpu"
    echo "────────────────────────────"
    echo
    
    read -p "$(print_color "$BLUE" "✅ Proceed? (Y/n): ")" confirm
    confirm=${confirm:-Y}
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_color "$YELLOW" "⚠️  Creation cancelled"
        pause
        return
    fi
    
    # Create container
    print_color "$CYAN" "📦 Creating container '$container_name'..."
    
    # Try different image sources
    local launch_success=0
    
    # Method 1: Try direct
    print_color "$BLUE" "🔄 Method 1: Trying images:$img..."
    if lxc launch $type_flag "images:$img" "$container_name" 2>/dev/null; then
        launch_success=1
    else
        # Method 2: Try without images: prefix
        print_color "$BLUE" "🔄 Method 2: Trying $img..."
        if lxc launch $type_flag "$img" "$container_name" 2>/dev/null; then
            launch_success=1
        else
            # Method 3: Try ubuntu: alias for Ubuntu
            if [[ "$img" == ubuntu:* ]]; then
                print_color "$BLUE" "🔄 Method 3: Trying ubuntu:$img..."
                if lxc launch $type_flag "ubuntu:${img#ubuntu:}" "$container_name" 2>/dev/null; then
                    launch_success=1
                fi
            fi
        fi
    fi
    
    if [[ $launch_success -eq 0 ]]; then
        print_color "$RED" "❌ Failed to create container!"
        print_color "$YELLOW" "💡 Available images:"
        lxc image list images: | head -10
        pause
        return
    fi
    
    # Configure resources
    print_color "$CYAN" "⚙️  Configuring resources..."
    
    lxc config set "$container_name" limits.cpu="$cpu" 2>/dev/null && \
        print_color "$GREEN" "✅ CPU set to $cpu cores"
    
    lxc config set "$container_name" limits.memory="$memory" 2>/dev/null && \
        print_color "$GREEN" "✅ Memory set to $memory"
    
    # Wait for container
    print_color "$BLUE" "⏳ Waiting for container to start..."
    sleep 5
    
    # Show info
    echo
    print_color "$GREEN" "🎉 Container '$container_name' created successfully!"
    echo
    
    print_color "$CYAN" "📊 Container Information:"
    lxc list "$container_name"
    
    # Get IP
    local ip=$(lxc list "$container_name" -c 4 --format csv 2>/dev/null)
    if [[ -n "$ip" && "$ip" != "-" ]]; then
        echo
        print_color "$GREEN" "🌐 IP Address: $ip"
        
        # Show connection info
        case $img in
            ubuntu:*)
                echo "👤 Default user: ubuntu"
                echo "🔑 No password (use SSH keys)"
                echo "🔌 SSH: ssh ubuntu@$ip"
                ;;
            debian:*)
                echo "👤 Default user: debian"
                echo "🔑 No password (use SSH keys)"
                echo "🔌 SSH: ssh debian@$ip"
                ;;
            *)
                echo "👤 Default user: root"
                echo "🔑 Set password on first login"
                echo "🔌 SSH: ssh root@$ip"
                ;;
        esac
    fi
    
    pause
}

# List containers
list_containers() {
    print_header
    print_color "$CYAN" "📋 Container List"
    echo "══════════════════════════════════════════════════════"
    
    if ! command -v lxc &> /dev/null; then
        print_color "$RED" "❌ LXC is not installed!"
        pause
        return
    fi
    
    # Show container list
    lxc list
    
    # Statistics
    local total=$(lxc list -c n --format csv 2>/dev/null | wc -l)
    local running=$(lxc list -c ns --format csv 2>/dev/null | grep "RUNNING" | wc -l)
    
    echo
    print_color "$BLUE" "📊 Statistics:"
    echo "Total containers: $total"
    echo "Running: $running"
    echo "Stopped: $((total - running))"
    
    pause
}

# Manage container
manage_container() {
    print_header
    print_color "$CYAN" "⚙️  Container Management"
    echo "══════════════════════════════════════════════════════"
    
    if ! command -v lxc &> /dev/null; then
        print_color "$RED" "❌ LXC is not installed!"
        pause
        return
    fi
    
    # Get containers
    local containers=$(lxc list -c n --format csv 2>/dev/null)
    
    if [[ -z "$containers" ]]; then
        print_color "$YELLOW" "📭 No containers found"
        pause
        return
    fi
    
    # Show containers
    print_color "$BLUE" "📦 Available Containers:"
    local i=1
    declare -A container_map
    for container in $containers; do
        container_map[$i]=$container
        local status=$(lxc list "$container" -c s --format csv 2>/dev/null)
        local status_icon="🔴"
        [[ "$status" == "RUNNING" ]] && status_icon="🟢"
        [[ "$status" == "FROZEN" ]] && status_icon="⏸️"
        echo "  $i) $status_icon $container ($status)"
        ((i++))
    done
    
    echo
    read -p "$(print_color "$BLUE" "🎯 Select container (1-$((i-1))) or 0 to cancel: ")" choice
    
    if [[ "$choice" == "0" ]]; then
        return
    fi
    
    local container_name=${container_map[$choice]}
    
    if [[ -z "$container_name" ]]; then
        print_color "$RED" "❌ Invalid selection!"
        pause
        return
    fi
    
    # Management menu
    while true; do
        print_header
        print_color "$CYAN" "⚙️  Managing: $container_name"
        echo "══════════════════════════════════════════════════════"
        
        local status=$(lxc list "$container_name" -c s --format csv 2>/dev/null)
        local ip=$(lxc list "$container_name" -c 4 --format csv 2>/dev/null | head -1)
        
        print_color "$BLUE" "📊 Status: $status"
        [[ -n "$ip" && "$ip" != "-" ]] && print_color "$GREEN" "🌐 IP: $ip"
        echo
        
        print_color "$YELLOW" "📋 Operations:"
        echo "1) ▶️  Start"
        echo "2) ⏹️  Stop"
        echo "3) 🔄 Restart"
        echo "4) ⏸️  Freeze"
        echo "5) ⏯️  Unfreeze"
        echo "6) 💻 Shell"
        echo "7) 📊 Info"
        echo "8) 📝 Logs"
        echo "9) ⚙️  Configure"
        echo "10) 📸 Snapshot"
        echo "11) 🗑️  Delete"
        echo "0) ↩️  Back"
        echo
        
        read -p "$(print_color "$BLUE" "🎯 Select operation: ")" operation
        
        case $operation in
            1)
                lxc start "$container_name" && print_color "$GREEN" "✅ Started"
                sleep 2
                ;;
            2)
                lxc stop "$container_name" && print_color "$GREEN" "✅ Stopped"
                sleep 2
                ;;
            3)
                lxc restart "$container_name" && print_color "$GREEN" "✅ Restarted"
                sleep 2
                ;;
            4)
                lxc freeze "$container_name" && print_color "$GREEN" "✅ Frozen"
                sleep 2
                ;;
            5)
                lxc unfreeze "$container_name" && print_color "$GREEN" "✅ Unfrozen"
                sleep 2
                ;;
            6)
                print_color "$CYAN" "💻 Opening shell (type 'exit' to return)..."
                lxc exec "$container_name" -- /bin/bash || lxc exec "$container_name" -- /bin/sh
                ;;
            7)
                lxc info "$container_name"
                pause
                ;;
            8)
                lxc info "$container_name" --show-log | tail -50
                pause
                ;;
            9)
                configure_container "$container_name"
                ;;
            10)
                read -p "Snapshot name: " snap_name
                lxc snapshot "$container_name" "$snap_name" && \
                    print_color "$GREEN" "✅ Snapshot created: $snap_name"
                pause
                ;;
            11)
                print_color "$RED" "⚠️  ⚠️  ⚠️  WARNING: This will delete '$container_name'!"
                read -p "Type 'DELETE' to confirm: " confirm
                if [[ "$confirm" == "DELETE" ]]; then
                    lxc delete "$container_name" --force && \
                        print_color "$GREEN" "✅ Container deleted"
                    pause
                    return
                else
                    print_color "$YELLOW" "⚠️  Deletion cancelled"
                    sleep 2
                fi
                ;;
            0)
                return
                ;;
            *)
                print_color "$RED" "❌ Invalid operation"
                sleep 1
                ;;
        esac
    done
}

# Configure container
configure_container() {
    local container_name=$1
    
    while true; do
        print_header
        print_color "$CYAN" "⚙️  Configuring: $container_name"
        echo "══════════════════════════════════════════════════════"
        
        print_color "$YELLOW" "📋 Configuration:"
        echo "1) ⚡ CPU"
        echo "2) 🧠 Memory"
        echo "3) 💾 Disk"
        echo "4) 🌐 Network"
        echo "5) 👁️  View config"
        echo "0) ↩️  Back"
        echo
        
        read -p "$(print_color "$BLUE" "🎯 Select option: ")" option
        
        case $option in
            1)
                read -p "CPU cores: " cpu
                lxc config set "$container_name" limits.cpu="$cpu" && \
                    print_color "$GREEN" "✅ CPU set to $cpu"
                pause
                ;;
            2)
                read -p "Memory (e.g., 2GB): " memory
                lxc config set "$container_name" limits.memory="$memory" && \
                    print_color "$GREEN" "✅ Memory set to $memory"
                pause
                ;;
            3)
                read -p "Disk size (e.g., 20GB): " disk
                lxc config device set "$container_name" root size="$disk" && \
                    print_color "$GREEN" "✅ Disk set to $disk"
                pause
                ;;
            4)
                echo "Available networks:"
                lxc network list
                read -p "Network name (default: lxdbr0): " network
                network=${network:-lxdbr0}
                lxc network attach "$network" "$container_name" eth0 && \
                    print_color "$GREEN" "✅ Attached to $network"
                pause
                ;;
            5)
                lxc config show "$container_name"
                pause
                ;;
            0)
                return
                ;;
            *)
                print_color "$RED" "❌ Invalid option"
                sleep 1
                ;;
        esac
    done
}

# System information
system_info() {
    print_header
    print_color "$CYAN" "📊 System Information"
    echo "══════════════════════════════════════════════════════"
    
    # Virtualization check
    check_virtualization
    echo
    
    # LXC/LXD info
    print_color "$YELLOW" "🐳 LXC/LXD Information:"
    if command -v lxc &> /dev/null; then
        lxc --version
        local containers=$(lxc list -c n --format csv 2>/dev/null | wc -l)
        echo "Containers: $containers"
        
        echo -e "\n📦 Storage:"
        lxc storage list 2>/dev/null || echo "  Not available"
        
        echo -e "\n🌐 Networks:"
        lxc network list 2>/dev/null || echo "  Not available"
    else
        echo "LXC not installed"
    fi
    
    # System info
    echo
    print_color "$YELLOW" "💻 System:"
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "OS: $PRETTY_NAME"
    fi
    echo "Kernel: $(uname -r)"
    echo "CPU: $(nproc) cores"
    echo "Memory: $(free -h | awk '/^Mem:/ {print $2}')"
    echo "Disk: $(df -h / | awk 'NR==2 {print $4}') free"
    
    pause
}

# Clean system
clean_system() {
    print_header
    print_color "$CYAN" "🧹 Clean System"
    echo "══════════════════════════════════════════════════════"
    
    if ! command -v lxc &> /dev/null; then
        print_color "$RED" "❌ LXC is not installed!"
        pause
        return
    fi
    
    print_color "$YELLOW" "📋 Cleaning Options:"
    echo "1) 🗑️  Remove stopped containers"
    echo "2) 🖼️  Remove unused images"
    echo "3) 📦 Remove all containers (DANGER!)"
    echo "0) ↩️  Back"
    echo
    
    read -p "$(print_color "$BLUE" "🎯 Select option: ")" option
    
    case $option in
        1)
            local stopped=$(lxc list -c ns --format csv 2>/dev/null | grep "STOPPED" | wc -l)
            if [[ $stopped -gt 0 ]]; then
                print_color "$YELLOW" "🗑️  Removing $stopped stopped containers..."
                lxc delete $(lxc list -c n --format csv 2>/dev/null | xargs -I {} lxc list {} -c ns --format csv | grep "STOPPED" | cut -d',' -f1)
                print_color "$GREEN" "✅ Stopped containers removed"
            else
                print_color "$YELLOW" "📭 No stopped containers found"
            fi
            ;;
        2)
            print_color "$YELLOW" "🖼️  Removing unused images..."
            lxc image list | grep -v "ALIAS" | awk '{print $2}' | xargs -I {} lxc image delete {}
            print_color "$GREEN" "✅ Unused images removed"
            ;;
        3)
            print_color "$RED" "🚨🚨🚨 DANGER: Remove ALL containers? 🚨🚨🚨"
            read -p "Type 'DELETE ALL' to confirm: " confirm
            if [[ "$confirm" == "DELETE ALL" ]]; then
                lxc delete --force $(lxc list -c n --format csv 2>/dev/null)
                print_color "$GREEN" "✅ All containers removed"
            else
                print_color "$YELLOW" "⚠️  Operation cancelled"
            fi
            ;;
        0)
            return
            ;;
        *)
            print_color "$RED" "❌ Invalid option"
            ;;
    esac
    
    pause
}

# Main menu
main_menu() {
    while true; do
        print_header
        
        # Show status
        if command -v lxc &> /dev/null; then
            local containers=$(lxc list -c n --format csv 2>/dev/null | wc -l)
            local running=$(lxc list -c ns --format csv 2>/dev/null | grep "RUNNING" | wc -l)
            echo -e "${GREEN}📦 LXC Status: $running/$containers containers running${NC}"
        else
            echo -e "${RED}❌ LXC not installed${NC}"
        fi
        
        echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}                    MAIN MENU                        ${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"
        echo
        
        echo -e "${WHITE}📦 CONTAINER MANAGEMENT${NC}"
        echo "  1) 🚀 Create container"
        echo "  2) 📋 List containers"
        echo "  3) ⚙️  Manage container"
        
        echo -e "\n${WHITE}🔧 SYSTEM TOOLS${NC}"
        echo "  4) 📊 System info"
        echo "  5) 🧹 Clean system"
        echo "  6) 🔍 Check installation"
        
        echo -e "\n${WHITE}⚙️ INSTALLATION${NC}"
        echo "  7) 🚀 Install LXC/LXD"
        
        echo -e "\n${WHITE}📋 OTHER${NC}"
        echo "  8) 🔄 Restart LXD service"
        echo "  0) 👋 Exit"
        
        echo -e "\n${CYAN}══════════════════════════════════════════════════════${NC}"
        
        read -p "$(print_color "$BLUE" "🎯 Select option (0-8): ")" choice
        
        case $choice in
            1) create_container ;;
            2) list_containers ;;
            3) manage_container ;;
            4) system_info ;;
            5) clean_system ;;
            6) 
                check_installation
                pause
                ;;
            7) install_dependencies ;;
            8)
                sudo systemctl restart snap.lxd.daemon 2>/dev/null || sudo systemctl restart lxd
                print_color "$GREEN" "✅ LXD service restarted"
                sleep 2
                ;;
            0)
                print_header
                print_color "$GREEN" "👋 Goodbye! Happy containerizing! 🐳"
                echo
                exit 0
                ;;
            *)
                print_color "$RED" "❌ Invalid option!"
                sleep 1
                ;;
        esac
    done
}

# Check if running in terminal
if [[ ! -t 0 ]]; then
    echo "This script must be run in a terminal!"
    exit 1
fi

# Start main menu
main_menu
