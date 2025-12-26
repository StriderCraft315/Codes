#!/bin/bash

# ============================================
# Docker Manager Script
# Version: 3.0
# Author: Docker Management System
# ============================================

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# ASCII Art Header
print_header() {
    clear
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║    ██████╗  ██████╗  ██████╗██╗  ██╗███████╗██████╗         ║"
    echo "║    ██╔══██╗██╔═══██╗██╔════╝██║ ██╔╝██╔════╝██╔══██╗        ║"
    echo "║    ██║  ██║██║   ██║██║     █████╔╝ █████╗  ██████╔╝        ║"
    echo "║    ██║  ██║██║   ██║██║     ██╔═██╗ ██╔══╝  ██╔══██╗        ║"
    echo "║    ██████╔╝╚██████╔╝╚██████╗██║  ██╗███████╗██║  ██║        ║"
    echo "║    ╚═════╝  ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝        ║"
    echo "║                                                              ║"
    echo "║                  DOCKER MANAGEMENT SYSTEM                    ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print section header
print_section() {
    local title=$1
    echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  $title${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"
}

# Function to check Docker installation
check_docker_installation() {
    print_section "🔍 Checking Docker Installation"
    
    if command -v docker &> /dev/null; then
        print_color "$GREEN" "✅ Docker is installed"
        DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | tr -d ',')
        print_color "$BLUE" "📦 Version: $DOCKER_VERSION"
        return 0
    else
        print_color "$RED" "❌ Docker is not installed!"
        return 1
    fi
}

# Function to check Docker Compose installation
check_docker_compose_installation() {
    if command -v docker-compose &> /dev/null; then
        print_color "$GREEN" "✅ Docker Compose is installed"
        COMPOSE_VERSION=$(docker-compose --version | cut -d' ' -f3 | tr -d ',')
        print_color "$BLUE" "📦 Version: $COMPOSE_VERSION"
        return 0
    elif docker compose version &> /dev/null; then
        print_color "$GREEN" "✅ Docker Compose (v2) is installed"
        COMPOSE_VERSION=$(docker compose version | grep -oP 'version \K[^\s,]+')
        print_color "$BLUE" "📦 Version: $COMPOSE_VERSION"
        return 0
    else
        print_color "$YELLOW" "⚠️  Docker Compose is not installed"
        return 1
    fi
}

# Function to check Docker service status
check_docker_service() {
    print_section "🔧 Checking Docker Service Status"
    
    if systemctl is-active --quiet docker; then
        print_color "$GREEN" "✅ Docker service is running"
    else
        print_color "$RED" "❌ Docker service is NOT running"
        return 1
    fi
    
    if systemctl is-enabled --quiet docker; then
        print_color "$GREEN" "✅ Docker service is enabled on boot"
    else
        print_color "$YELLOW" "⚠️  Docker service is NOT enabled on boot"
    fi
}

# Function to install Docker
install_docker() {
    print_header
    print_section "🚀 Installing Docker"
    
    # Check if already installed
    if check_docker_installation; then
        print_color "$YELLOW" "⚠️  Docker is already installed"
        read -p "Reinstall? (y/N): " reinstall
        if [[ ! "$reinstall" =~ ^[Yy]$ ]]; then
            return
        fi
    fi
    
    # Detect OS
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
    else
        print_color "$RED" "❌ Cannot detect OS"
        return 1
    fi
    
    print_color "$BLUE" "📊 Detected OS: $PRETTY_NAME"
    
    case $OS in
        ubuntu|debian)
            install_docker_debian
            ;;
        centos|rhel|fedora|rocky|almalinux)
            install_docker_rhel
            ;;
        *)
            print_color "$RED" "❌ Unsupported OS: $OS"
            print_color "$YELLOW" "📋 Please install Docker manually from: https://docs.docker.com/engine/install/"
            return 1
            ;;
    esac
    
    # Post-installation steps
    print_section "⚙️  Post-Installation Configuration"
    
    # Add user to docker group
    print_color "$CYAN" "👤 Adding user to docker group..."
    sudo usermod -aG docker $USER
    
    # Enable and start Docker service
    print_color "$CYAN" "▶️  Starting Docker service..."
    sudo systemctl enable docker
    sudo systemctl start docker
    
    print_color "$GREEN" "✅ Docker installed successfully!"
    print_color "$YELLOW" "⚠️  Please log out and log back in for group changes to take effect"
}

# Function to install Docker on Debian/Ubuntu
install_docker_debian() {
    print_color "$CYAN" "📦 Installing Docker for Debian/Ubuntu..."
    
    # Update packages
    sudo apt update
    
    # Install prerequisites
    sudo apt install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # Add Docker GPG key
    curl -fsSL https://download.docker.com/linux/$OS/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$OS \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update and install Docker
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
}

# Function to install Docker on RHEL/CentOS/Fedora
install_docker_rhel() {
    print_color "$CYAN" "📦 Installing Docker for RHEL/CentOS/Fedora..."
    
    # Remove old versions
    sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
    
    # Install prerequisites
    sudo yum install -y yum-utils
    
    # Add Docker repository
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    
    # Install Docker
    sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # For Fedora
    if [[ "$OS" == "fedora" ]]; then
        sudo dnf install -y dnf-plugins-core
        sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
        sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    fi
}

# Function to install Docker Compose
install_docker_compose() {
    print_header
    print_section "📦 Installing Docker Compose"
    
    # Check if already installed
    if docker compose version &> /dev/null || command -v docker-compose &> /dev/null; then
        print_color "$YELLOW" "⚠️  Docker Compose is already installed"
        read -p "Reinstall? (y/N): " reinstall
        if [[ ! "$reinstall" =~ ^[Yy]$ ]]; then
            return
        fi
    fi
    
    print_color "$CYAN" "Select installation method:"
    echo "1) Official Docker Compose (Recommended)"
    echo "2) Docker Compose Plugin (v2)"
    echo "3) From repository"
    read -p "Choice (1-3): " method
    
    case $method in
        1)
            # Install official Docker Compose
            print_color "$BLUE" "📥 Downloading Docker Compose..."
            sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
            ;;
        2)
            # Install as Docker plugin
            print_color "$BLUE" "📥 Installing Docker Compose Plugin..."
            sudo apt-get update
            sudo apt-get install -y docker-compose-plugin
            ;;
        3)
            # Install from repository
            print_color "$BLUE" "📥 Installing from repository..."
            sudo apt-get update
            sudo apt-get install -y docker-compose
            ;;
        *)
            print_color "$RED" "❌ Invalid choice"
            return 1
            ;;
    esac
    
    # Verify installation
    if docker compose version &> /dev/null || command -v docker-compose &> /dev/null; then
        print_color "$GREEN" "✅ Docker Compose installed successfully!"
        
        # Show version
        if command -v docker-compose &> /dev/null; then
            docker-compose --version
        elif docker compose version &> /dev/null; then
            docker compose version
        fi
    else
        print_color "$RED" "❌ Failed to install Docker Compose"
    fi
}

# Function to list Docker containers
list_containers() {
    print_header
    print_section "📋 Docker Containers"
    
    if ! check_docker_installation; then
        return 1
    fi
    
    echo -e "${YELLOW}Options:${NC}"
    echo "1) All containers (default)"
    echo "2) Running containers only"
    echo "3) Stopped containers only"
    echo "4) Detailed view"
    read -p "Select option (1-4): " option
    
    case $option in
        1|"")
            print_color "$CYAN" "📦 All Containers:"
            docker ps -a
            ;;
        2)
            print_color "$CYAN" "▶️  Running Containers:"
            docker ps
            ;;
        3)
            print_color "$CYAN" "⏹️  Stopped Containers:"
            docker ps -a -f "status=exited"
            ;;
        4)
            print_color "$CYAN" "📊 Detailed View:"
            docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}\t{{.CreatedAt}}"
            ;;
        *)
            print_color "$RED" "❌ Invalid option"
            ;;
    esac
    
    # Show container count
    local total=$(docker ps -a -q | wc -l)
    local running=$(docker ps -q | wc -l)
    local stopped=$((total - running))
    
    echo -e "\n${GREEN}📊 Container Statistics:${NC}"
    echo "Total: $total | Running: $running | Stopped: $stopped"
}

# Function to list Docker images
list_images() {
    print_header
    print_section "🖼️ Docker Images"
    
    if ! check_docker_installation; then
        return 1
    fi
    
    echo -e "${YELLOW}Options:${NC}"
    echo "1) All images (default)"
    echo "2) Filter by name"
    echo "3) Show disk usage"
    read -p "Select option (1-3): " option
    
    case $option in
        1|"")
            print_color "$CYAN" "📦 All Images:"
            docker images
            ;;
        2)
            read -p "Enter image name filter: " filter
            print_color "$CYAN" "🔍 Images matching '$filter':"
            docker images | grep -i "$filter"
            ;;
        3)
            print_color "$CYAN" "💾 Disk Usage:"
            docker system df
            ;;
        *)
            print_color "$RED" "❌ Invalid option"
            ;;
    esac
    
    # Show image count
    local image_count=$(docker images -q | wc -l)
    echo -e "\n${GREEN}📊 Total Images: $image_count${NC}"
}

# Function to run a container
run_container() {
    print_header
    print_section "🚀 Run New Container"
    
    if ! check_docker_installation; then
        return 1
    fi
    
    # Quick run popular images
    print_color "$YELLOW" "🏃 Quick Run - Popular Images:"
    echo "1) 🐳 Nginx (Web server)"
    echo "2) 🗄️  MySQL (Database)"
    echo "3) 🐘 PostgreSQL (Database)"
    echo "4) 🔥 Redis (Cache)"
    echo "5) 📦 Alpine (Lightweight Linux)"
    echo "6) 🐍 Python (Latest)"
    echo "7) 🔧 Custom Image"
    echo "0) ↩️  Back"
    echo
    
    read -p "Select option (0-7): " quick_option
    
    case $quick_option in
        1) IMAGE="nginx"; PORT="80:80"; NAME="nginx-web" ;;
        2) IMAGE="mysql:latest"; PORT="3306:3306"; NAME="mysql-db" ;;
        3) IMAGE="postgres:latest"; PORT="5432:5432"; NAME="postgres-db" ;;
        4) IMAGE="redis:alpine"; PORT="6379:6379"; NAME="redis-cache" ;;
        5) IMAGE="alpine:latest"; PORT=""; NAME="alpine-test" ;;
        6) IMAGE="python:latest"; PORT=""; NAME="python-app" ;;
        7)
            read -p "Enter image name: " IMAGE
            read -p "Enter container name (optional): " NAME
            read -p "Enter port mapping (e.g., 8080:80) or leave empty: " PORT
            ;;
        0) return ;;
        *) 
            print_color "$RED" "❌ Invalid option"
            return 1
            ;;
    esac
    
    if [[ -z "$IMAGE" ]]; then
        print_color "$RED" "❌ Image name is required"
        return 1
    fi
    
    # Build Docker command
    local DOCKER_CMD="docker run -d"
    
    # Add name if specified
    if [[ -n "$NAME" ]]; then
        DOCKER_CMD="$DOCKER_CMD --name $NAME"
    fi
    
    # Add port mapping if specified
    if [[ -n "$PORT" ]]; then
        DOCKER_CMD="$DOCKER_CMD -p $PORT"
    fi
    
    # Add image
    DOCKER_CMD="$DOCKER_CMD $IMAGE"
    
    # Show command
    print_color "$CYAN" "📝 Command to execute:"
    echo "$DOCKER_CMD"
    echo
    
    read -p "Proceed? (Y/n): " confirm
    confirm=${confirm:-Y}
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        # Execute command
        print_color "$BLUE" "🚀 Running container..."
        eval $DOCKER_CMD
        
        if [[ $? -eq 0 ]]; then
            print_color "$GREEN" "✅ Container started successfully!"
            
            # Show container info
            echo
            docker ps -l --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
        else
            print_color "$RED" "❌ Failed to start container"
        fi
    else
        print_color "$YELLOW" "⚠️  Operation cancelled"
    fi
}

# Function to stop container
stop_container() {
    print_header
    print_section "⏹️ Stop Container"
    
    if ! check_docker_installation; then
        return 1
    fi
    
    # Get running containers
    local containers=$(docker ps --format "{{.Names}}")
    
    if [[ -z "$containers" ]]; then
        print_color "$YELLOW" "📭 No running containers found"
        return 0
    fi
    
    print_color "$CYAN" "▶️  Running Containers:"
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
    echo
    
    echo -e "${YELLOW}Options:${NC}"
    echo "1) Stop specific container"
    echo "2) Stop all running containers"
    echo "0) Back"
    read -p "Select option (0-2): " option
    
    case $option in
        1)
            read -p "Enter container name: " container_name
            if docker stop "$container_name" &> /dev/null; then
                print_color "$GREEN" "✅ Container '$container_name' stopped successfully"
            else
                print_color "$RED" "❌ Failed to stop container '$container_name'"
            fi
            ;;
        2)
            print_color "$YELLOW" "⚠️  This will stop ALL running containers!"
            read -p "Are you sure? (y/N): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                docker stop $(docker ps -q)
                print_color "$GREEN" "✅ All containers stopped"
            else
                print_color "$YELLOW" "⚠️  Operation cancelled"
            fi
            ;;
        0) return ;;
        *) print_color "$RED" "❌ Invalid option" ;;
    esac
}

# Function to start container
start_container() {
    print_header
    print_section "▶️ Start Container"
    
    if ! check_docker_installation; then
        return 1
    fi
    
    # Get stopped containers
    local containers=$(docker ps -a --filter "status=exited" --format "{{.Names}}")
    
    if [[ -z "$containers" ]]; then
        print_color "$YELLOW" "📭 No stopped containers found"
        return 0
    fi
    
    print_color "$CYAN" "⏹️  Stopped Containers:"
    docker ps -a --filter "status=exited" --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
    echo
    
    echo -e "${YELLOW}Options:${NC}"
    echo "1) Start specific container"
    echo "2) Start all stopped containers"
    echo "0) Back"
    read -p "Select option (0-2): " option
    
    case $option in
        1)
            read -p "Enter container name: " container_name
            if docker start "$container_name" &> /dev/null; then
                print_color "$GREEN" "✅ Container '$container_name' started successfully"
            else
                print_color "$RED" "❌ Failed to start container '$container_name'"
            fi
            ;;
        2)
            print_color "$YELLOW" "⚠️  This will start ALL stopped containers!"
            read -p "Are you sure? (y/N): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                docker start $(docker ps -a -q --filter "status=exited")
                print_color "$GREEN" "✅ All containers started"
            else
                print_color "$YELLOW" "⚠️  Operation cancelled"
            fi
            ;;
        0) return ;;
        *) print_color "$RED" "❌ Invalid option" ;;
    esac
}

# Function to remove container
remove_container() {
    print_header
    print_section "🗑️ Remove Container"
    
    if ! check_docker_installation; then
        return 1
    fi
    
    # Get all containers
    local containers=$(docker ps -a --format "{{.Names}}")
    
    if [[ -z "$containers" ]]; then
        print_color "$YELLOW" "📭 No containers found"
        return 0
    fi
    
    print_color "$CYAN" "📦 All Containers:"
    docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
    echo
    
    echo -e "${YELLOW}Options:${NC}"
    echo "1) Remove specific container"
    echo "2) Remove all stopped containers"
    echo "3) Remove all containers (DANGER!)"
    echo "0) Back"
    read -p "Select option (0-3): " option
    
    case $option in
        1)
            read -p "Enter container name: " container_name
            print_color "$RED" "⚠️  Removing container '$container_name'"
            read -p "Remove with force? (y/N): " force
            if [[ "$force" =~ ^[Yy]$ ]]; then
                docker rm -f "$container_name"
            else
                docker rm "$container_name"
            fi
            
            if [[ $? -eq 0 ]]; then
                print_color "$GREEN" "✅ Container removed successfully"
            else
                print_color "$RED" "❌ Failed to remove container"
            fi
            ;;
        2)
            print_color "$YELLOW" "⚠️  This will remove ALL stopped containers!"
            read -p "Are you sure? (y/N): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                docker container prune -f
                print_color "$GREEN" "✅ All stopped containers removed"
            else
                print_color "$YELLOW" "⚠️  Operation cancelled"
            fi
            ;;
        3)
            print_color "$RED" "🚨🚨🚨 DANGER: This will remove ALL containers! 🚨🚨🚨"
            read -p "Type 'DELETE ALL' to confirm: " confirm
            if [[ "$confirm" == "DELETE ALL" ]]; then
                docker rm -f $(docker ps -a -q)
                print_color "$GREEN" "✅ All containers removed"
            else
                print_color "$YELLOW" "⚠️  Operation cancelled"
            fi
            ;;
        0) return ;;
        *) print_color "$RED" "❌ Invalid option" ;;
    esac
}

# Function to remove images
remove_images() {
    print_header
    print_section "🗑️ Remove Docker Images"
    
    if ! check_docker_installation; then
        return 1
    fi
    
    print_color "$CYAN" "🖼️  Current Images:"
    docker images
    echo
    
    echo -e "${YELLOW}Options:${NC}"
    echo "1) Remove specific image"
    echo "2) Remove dangling images"
    echo "3) Remove all unused images"
    echo "4) Remove all images (DANGER!)"
    echo "0) Back"
    read -p "Select option (0-4): " option
    
    case $option in
        1)
            read -p "Enter image name: " image_name
            print_color "$RED" "⚠️  Removing image '$image_name'"
            read -p "Force remove? (y/N): " force
            if [[ "$force" =~ ^[Yy]$ ]]; then
                docker rmi -f "$image_name"
            else
                docker rmi "$image_name"
            fi
            ;;
        2)
            print_color "$YELLOW" "⚠️  Removing dangling images..."
            docker image prune -f
            print_color "$GREEN" "✅ Dangling images removed"
            ;;
        3)
            print_color "$YELLOW" "⚠️  Removing all unused images..."
            docker image prune -a -f
            print_color "$GREEN" "✅ All unused images removed"
            ;;
        4)
            print_color "$RED" "🚨🚨🚨 DANGER: This will remove ALL images! 🚨🚨🚨"
            read -p "Type 'DELETE ALL IMAGES' to confirm: " confirm
            if [[ "$confirm" == "DELETE ALL IMAGES" ]]; then
                docker rmi -f $(docker images -q)
                print_color "$GREEN" "✅ All images removed"
            else
                print_color "$YELLOW" "⚠️  Operation cancelled"
            fi
            ;;
        0) return ;;
        *) print_color "$RED" "❌ Invalid option" ;;
    esac
}

# Function to view container logs
view_logs() {
    print_header
    print_section "📝 Container Logs"
    
    if ! check_docker_installation; then
        return 1
    fi
    
    # Get running containers
    local containers=$(docker ps --format "{{.Names}}")
    
    if [[ -z "$containers" ]]; then
        print_color "$YELLOW" "📭 No running containers found"
        return 0
    fi
    
    print_color "$CYAN" "▶️  Running Containers:"
    select container in $containers "Back"; do
        if [[ "$container" == "Back" ]]; then
            return
        elif [[ -n "$container" ]]; then
            print_color "$BLUE" "📖 Showing logs for: $container"
            echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
            docker logs -f --tail 100 "$container"
            echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
            print_color "$YELLOW" "Press Ctrl+C to stop viewing logs"
            return
        else
            print_color "$RED" "❌ Invalid selection"
        fi
    done
}

# Function to execute command in container
exec_command() {
    print_header
    print_section "💻 Execute Command in Container"
    
    if ! check_docker_installation; then
        return 1
    fi
    
    # Get running containers
    local containers=$(docker ps --format "{{.Names}}")
    
    if [[ -z "$containers" ]]; then
        print_color "$YELLOW" "📭 No running containers found"
        return 0
    fi
    
    print_color "$CYAN" "▶️  Running Containers:"
    select container in $containers "Back"; do
        if [[ "$container" == "Back" ]]; then
            return
        elif [[ -n "$container" ]]; then
            print_color "$BLUE" "💻 Selected container: $container"
            
            echo -e "${YELLOW}Quick commands:${NC}"
            echo "1) bash"
            echo "2) sh"
            echo "3) ps aux"
            echo "4) Custom command"
            read -p "Select option (1-4): " cmd_option
            
            case $cmd_option in
                1) CMD="bash" ;;
                2) CMD="sh" ;;
                3) CMD="ps aux" ;;
                4)
                    read -p "Enter command: " CMD
                    if [[ -z "$CMD" ]]; then
                        print_color "$RED" "❌ Command cannot be empty"
                        return 1
                    fi
                    ;;
                *)
                    print_color "$RED" "❌ Invalid option"
                    return 1
                    ;;
            esac
            
            print_color "$CYAN" "🚀 Executing: $CMD"
            echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
            docker exec -it "$container" $CMD
            echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
            return
        else
            print_color "$RED" "❌ Invalid selection"
        fi
    done
}

# Function to build Docker image
build_image() {
    print_header
    print_section "🔨 Build Docker Image"
    
    if ! check_docker_installation; then
        return 1
    fi
    
    echo -e "${YELLOW}Options:${NC}"
    echo "1) Build from current directory"
    echo "2) Build from specific directory"
    echo "3) Build with custom Dockerfile"
    echo "0) Back"
    read -p "Select option (0-3): " option
    
    case $option in
        1)
            if [[ -f "Dockerfile" ]]; then
                read -p "Enter image name (e.g., myapp:latest): " image_name
                if [[ -n "$image_name" ]]; then
                    print_color "$BLUE" "🔨 Building image: $image_name"
                    docker build -t "$image_name" .
                    
                    if [[ $? -eq 0 ]]; then
                        print_color "$GREEN" "✅ Image built successfully!"
                    else
                        print_color "$RED" "❌ Failed to build image"
                    fi
                else
                    print_color "$RED" "❌ Image name is required"
                fi
            else
                print_color "$RED" "❌ Dockerfile not found in current directory"
            fi
            ;;
        2)
            read -p "Enter directory path: " dir_path
            if [[ -d "$dir_path" && -f "$dir_path/Dockerfile" ]]; then
                read -p "Enter image name (e.g., myapp:latest): " image_name
                if [[ -n "$image_name" ]]; then
                    print_color "$BLUE" "🔨 Building image: $image_name from $dir_path"
                    docker build -t "$image_name" "$dir_path"
                    
                    if [[ $? -eq 0 ]]; then
                        print_color "$GREEN" "✅ Image built successfully!"
                    else
                        print_color "$RED" "❌ Failed to build image"
                    fi
                else
                    print_color "$RED" "❌ Image name is required"
                fi
            else
                print_color "$RED" "❌ Dockerfile not found in $dir_path"
            fi
            ;;
        3)
            read -p "Enter Dockerfile path: " dockerfile_path
            if [[ -f "$dockerfile_path" ]]; then
                read -p "Enter image name (e.g., myapp:latest): " image_name
                if [[ -n "$image_name" ]]; then
                    print_color "$BLUE" "🔨 Building image: $image_name using $dockerfile_path"
                    docker build -t "$image_name" -f "$dockerfile_path" .
                    
                    if [[ $? -eq 0 ]]; then
                        print_color "$GREEN" "✅ Image built successfully!"
                    else
                        print_color "$RED" "❌ Failed to build image"
                    fi
                else
                    print_color "$RED" "❌ Image name is required"
                fi
            else
                print_color "$RED" "❌ Dockerfile not found: $dockerfile_path"
            fi
            ;;
        0) return ;;
        *) print_color "$RED" "❌ Invalid option" ;;
    esac
}

# Function to manage Docker Compose
manage_compose() {
    print_header
    print_section "📦 Docker Compose Management"
    
    if ! check_docker_compose_installation; then
        print_color "$YELLOW" "⚠️  Docker Compose is not installed"
        read -p "Install Docker Compose now? (Y/n): " install
        if [[ "$install" =~ ^[Yy]?$ ]]; then
            install_docker_compose
        fi
        return
    fi
    
    echo -e "${YELLOW}Options:${NC}"
    echo "1) 📋 Compose status"
    echo "2) 🚀 Start services"
    echo "3) ⏹️  Stop services"
    echo "4) 🔄 Restart services"
    echo "5) 📊 View logs"
    echo "6) 📦 Build images"
    echo "7) ⬆️  Up with build"
    echo "8) ⬇️  Down (remove)"
    echo "0) ↩️  Back"
    echo
    
    read -p "Select option (0-8): " option
    
    # Check for docker-compose.yml
    local compose_file=""
    if [[ -f "docker-compose.yml" ]]; then
        compose_file="docker-compose.yml"
    elif [[ -f "docker-compose.yaml" ]]; then
        compose_file="docker-compose.yaml"
    fi
    
    # Determine compose command
    local compose_cmd="docker-compose"
    if docker compose version &> /dev/null; then
        compose_cmd="docker compose"
    fi
    
    # Add file if exists
    if [[ -n "$compose_file" ]]; then
        compose_cmd="$compose_cmd -f $compose_file"
        print_color "$GREEN" "📄 Using compose file: $compose_file"
    else
        print_color "$YELLOW" "⚠️  No docker-compose.yml found in current directory"
        read -p "Enter path to docker-compose.yml: " custom_file
        if [[ -f "$custom_file" ]]; then
            compose_cmd="$compose_cmd -f $custom_file"
        else
            print_color "$RED" "❌ File not found: $custom_file"
            return 1
        fi
    fi
    
    case $option in
        1)
            print_color "$CYAN" "📋 Compose Status:"
            $compose_cmd ps
            ;;
        2)
            print_color "$BLUE" "🚀 Starting services..."
            $compose_cmd up -d
            if [[ $? -eq 0 ]]; then
                print_color "$GREEN" "✅ Services started successfully!"
            fi
            ;;
        3)
            print_color "$YELLOW" "⏹️  Stopping services..."
            $compose_cmd stop
            if [[ $? -eq 0 ]]; then
                print_color "$GREEN" "✅ Services stopped successfully!"
            fi
            ;;
        4)
            print_color "$BLUE" "🔄 Restarting services..."
            $compose_cmd restart
            if [[ $? -eq 0 ]]; then
                print_color "$GREEN" "✅ Services restarted successfully!"
            fi
            ;;
        5)
            print_color "$CYAN" "📊 Viewing logs..."
            $compose_cmd logs -f --tail 100
            ;;
        6)
            print_color "$BLUE" "📦 Building images..."
            $compose_cmd build
            if [[ $? -eq 0 ]]; then
                print_color "$GREEN" "✅ Images built successfully!"
            fi
            ;;
        7)
            print_color "$BLUE" "⬆️  Starting services with build..."
            $compose_cmd up -d --build
            if [[ $? -eq 0 ]]; then
                print_color "$GREEN" "✅ Services started with build!"
            fi
            ;;
        8)
            print_color "$RED" "⚠️  This will stop and remove all containers, networks, and volumes!"
            read -p "Are you sure? (y/N): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                print_color "$RED" "🗑️  Removing services..."
                $compose_cmd down -v
                print_color "$GREEN" "✅ All services removed!"
            else
                print_color "$YELLOW" "⚠️  Operation cancelled"
            fi
            ;;
        0) return ;;
        *) print_color "$RED" "❌ Invalid option" ;;
    esac
}

# Function to clean Docker system
clean_system() {
    print_header
    print_section "🧹 Clean Docker System"
    
    if ! check_docker_installation; then
        return 1
    fi
    
    print_color "$CYAN" "📊 Current Docker Disk Usage:"
    docker system df
    echo
    
    echo -e "${YELLOW}Cleaning Options:${NC}"
    echo "1) 🗑️  Remove stopped containers"
    echo "2) 🖼️  Remove dangling images"
    echo "3) 📦 Remove unused images"
    echo "4) 🗂️  Remove unused volumes"
    echo "5) 🧹 Remove unused networks"
    echo "6) 💣 Remove everything (prune all)"
    echo "7) 📊 Show what would be removed"
    echo "0) ↩️  Back"
    echo
    
    read -p "Select option (0-7): " option
    
    case $option in
        1)
            print_color "$YELLOW" "🗑️  Removing stopped containers..."
            docker container prune -f
            print_color "$GREEN" "✅ Stopped containers removed"
            ;;
        2)
            print_color "$YELLOW" "🖼️  Removing dangling images..."
            docker image prune -f
            print_color "$GREEN" "✅ Dangling images removed"
            ;;
        3)
            print_color "$YELLOW" "📦 Removing unused images..."
            docker image prune -a -f
            print_color "$GREEN" "✅ Unused images removed"
            ;;
        4)
            print_color "$YELLOW" "🗂️  Removing unused volumes..."
            docker volume prune -f
            print_color "$GREEN" "✅ Unused volumes removed"
            ;;
        5)
            print_color "$YELLOW" "🧹 Removing unused networks..."
            docker network prune -f
            print_color "$GREEN" "✅ Unused networks removed"
            ;;
        6)
            print_color "$RED" "💣 This will remove ALL unused data!"
            read -p "Are you sure? (y/N): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                docker system prune -a -f --volumes
                print_color "$GREEN" "✅ All unused Docker data removed!"
            else
                print_color "$YELLOW" "⚠️  Operation cancelled"
            fi
            ;;
        7)
            print_color "$CYAN" "📊 What would be removed:"
            echo "Containers:"
            docker container ls -a --filter status=exited
            echo -e "\nImages:"
            docker images -f dangling=true
            echo -e "\nVolumes:"
            docker volume ls -f dangling=true
            echo -e "\nNetworks:"
            docker network ls --filter dangling=true
            ;;
        0) return ;;
        *) print_color "$RED" "❌ Invalid option" ;;
    esac
}

# Function to show Docker info
show_docker_info() {
    print_header
    print_section "📊 Docker Information"
    
    if ! check_docker_installation; then
        return 1
    fi
    
    print_color "$CYAN" "🐳 Docker Version:"
    docker version --format '{{.Client.Version}}' 2>/dev/null && \
    docker version --format '{{.Server.Version}}' 2>/dev/null
    echo
    
    print_color "$CYAN" "📦 Docker Info:"
    docker info --format '{{json .}}' 2>/dev/null | python3 -m json.tool 2>/dev/null | \
        grep -E '(Containers|Running|Paused|Stopped|Images|Server Version|Storage Driver|Logging Driver|Cgroup Driver|Plugins|Total Memory|CPUs|OSType|Architecture)' | \
        head -20
    
    echo
    print_color "$CYAN" "🌐 Docker Networks:"
    docker network ls
    
    echo
    print_color "$CYAN" "💾 Docker Volumes:"
    docker volume ls
}

# Function to monitor Docker resources
monitor_resources() {
    print_header
    print_section "📈 Docker Resource Monitor"
    
    if ! check_docker_installation; then
        return 1
    fi
    
    echo -e "${YELLOW}Monitoring Options:${NC}"
    echo "1) 📊 Live container stats"
    echo "2) 📈 System resource usage"
    echo "3) 🧠 Memory usage by container"
    echo "4) ⚡ CPU usage by container"
    echo "5) 💾 Disk usage"
    echo "0) ↩️  Back"
    echo
    
    read -p "Select option (0-5): " option
    
    case $option in
        1)
            print_color "$CYAN" "📊 Live Container Stats (Ctrl+C to exit):"
            docker stats
            ;;
        2)
            print_color "$CYAN" "📈 System Resource Usage:"
            docker system df -v
            ;;
        3)
            print_color "$CYAN" "🧠 Memory Usage by Container:"
            docker stats --no-stream --format "table {{.Name}}\t{{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" | sort -k5 -h -r
            ;;
        4)
            print_color "$CYAN" "⚡ CPU Usage by Container:"
            docker stats --no-stream --format "table {{.Name}}\t{{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" | sort -k3 -h -r
            ;;
        5)
            print_color "$CYAN" "💾 Disk Usage Details:"
            docker system df
            echo
            print_color "$BLUE" "📦 Images disk usage:"
            docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | sort
            ;;
        0) return ;;
        *) print_color "$RED" "❌ Invalid option" ;;
    esac
}

# Function to backup and restore
backup_restore() {
    print_header
    print_section "💾 Backup & Restore"
    
    if ! check_docker_installation; then
        return 1
    fi
    
    echo -e "${YELLOW}Options:${NC}"
    echo "1) 💾 Backup container"
    echo "2) 📤 Export container"
    echo "3) 📥 Import container"
    echo "4) 💿 Save image"
    echo "5) 📀 Load image"
    echo "0) ↩️  Back"
    echo
    
    read -p "Select option (0-5): " option
    
    case $option in
        1)
            read -p "Enter container name: " container_name
            read -p "Enter backup filename (e.g., backup.tar): " backup_file
            if [[ -n "$container_name" && -n "$backup_file" ]]; then
                print_color "$BLUE" "💾 Creating backup of $container_name to $backup_file..."
                docker commit -p "$container_name" "${container_name}_backup"
                docker save -o "$backup_file" "${container_name}_backup"
                print_color "$GREEN" "✅ Backup created successfully!"
            fi
            ;;
        2)
            read -p "Enter container name: " container_name
            read -p "Enter export filename (e.g., export.tar): " export_file
            if [[ -n "$container_name" && -n "$export_file" ]]; then
                print_color "$BLUE" "📤 Exporting $container_name to $export_file..."
                docker export "$container_name" > "$export_file"
                print_color "$GREEN" "✅ Container exported successfully!"
            fi
            ;;
        3)
            read -p "Enter import filename (e.g., import.tar): " import_file
            read -p "Enter new image name (e.g., imported:latest): " image_name
            if [[ -f "$import_file" && -n "$image_name" ]]; then
                print_color "$BLUE" "📥 Importing $import_file as $image_name..."
                docker import "$import_file" "$image_name"
                print_color "$GREEN" "✅ Container imported successfully!"
            else
                print_color "$RED" "❌ File not found or image name missing"
            fi
            ;;
        4)
            read -p "Enter image name: " image_name
            read -p "Enter save filename (e.g., image.tar): " save_file
            if [[ -n "$image_name" && -n "$save_file" ]]; then
                print_color "$BLUE" "💿 Saving image $image_name to $save_file..."
                docker save -o "$save_file" "$image_name"
                print_color "$GREEN" "✅ Image saved successfully!"
            fi
            ;;
        5)
            read -p "Enter load filename (e.g., image.tar): " load_file
            if [[ -f "$load_file" ]]; then
                print_color "$BLUE" "📀 Loading image from $load_file..."
                docker load -i "$load_file"
                print_color "$GREEN" "✅ Image loaded successfully!"
            else
                print_color "$RED" "❌ File not found: $load_file"
            fi
            ;;
        0) return ;;
        *) print_color "$RED" "❌ Invalid option" ;;
    esac
}

# Function to show quick commands
show_quick_commands() {
    print_header
    print_section "⚡ Quick Docker Commands"
    
    echo -e "${GREEN}🐳 Basic Commands:${NC}"
    echo "  docker ps                         # List running containers"
    echo "  docker ps -a                      # List all containers"
    echo "  docker images                     # List images"
    echo "  docker run <image>                # Run container"
    echo "  docker stop <container>           # Stop container"
    echo "  docker start <container>          # Start container"
    echo "  docker rm <container>             # Remove container"
    echo "  docker rmi <image>                # Remove image"
    
    echo -e "\n${YELLOW}🔍 Inspection Commands:${NC}"
    echo "  docker logs <container>           # View logs"
    echo "  docker exec -it <container> bash  # Enter container"
    echo "  docker inspect <container>        # Inspect container"
    echo "  docker stats                      # Live container stats"
    
    echo -e "\n${BLUE}📦 Image Commands:${NC}"
    echo "  docker build -t <name> .          # Build image"
    echo "  docker pull <image>               # Pull image"
    echo "  docker push <image>               # Push image"
    echo "  docker save <image> > file.tar    # Save image"
    echo "  docker load < file.tar            # Load image"
    
    echo -e "\n${PURPLE}🧹 Cleanup Commands:${NC}"
    echo "  docker system prune               # Remove unused data"
    echo "  docker container prune            # Remove stopped containers"
    echo "  docker image prune                # Remove unused images"
    echo "  docker volume prune               # Remove unused volumes"
    
    echo -e "\n${CYAN}📊 Information Commands:${NC}"
    echo "  docker version                    # Docker version"
    echo "  docker info                       # Docker system info"
    echo "  docker system df                  # Disk usage"
    
    echo -e "\n${RED}🚨 Dangerous Commands:${NC}"
    echo "  docker rm -f \$(docker ps -aq)    # Remove ALL containers"
    echo "  docker rmi -f \$(docker images -q) # Remove ALL images"
    echo "  docker system prune -a --volumes  # Remove EVERYTHING"
    
    echo -e "\n${WHITE}📋 Docker Compose Commands:${NC}"
    echo "  docker-compose up -d              # Start services"
    echo "  docker-compose down               # Stop services"
    echo "  docker-compose logs               # View logs"
    echo "  docker-compose ps                 # List services"
    
    read -p "⏎ Press Enter to continue..."
}

# Function to show system status
show_system_status() {
    print_header
    print_section "📊 System Status"
    
    # Check Docker installation
    if check_docker_installation; then
        # Container count
        local total_containers=$(docker ps -a -q | wc -l)
        local running_containers=$(docker ps -q | wc -l)
        
        # Image count
        local total_images=$(docker images -q | wc -l)
        
        # Volume count
        local total_volumes=$(docker volume ls -q | wc -l 2>/dev/null || echo "0")
        
        # Network count
        local total_networks=$(docker network ls -q | wc -l)
        
        print_color "$GREEN" "✅ Docker Status:"
        echo "  📦 Containers: $running_containers/$total_containers (running/total)"
        echo "  🖼️  Images: $total_images"
        echo "  💾 Volumes: $total_volumes"
        echo "  🌐 Networks: $total_networks"
        
        # Docker Compose status
        if check_docker_compose_installation; then
            print_color "$GREEN" "✅ Docker Compose: Installed"
        else
            print_color "$YELLOW" "⚠️  Docker Compose: Not installed"
        fi
    else
        print_color "$RED" "❌ Docker: Not installed"
    fi
    
    # System resources
    echo
    print_color "$CYAN" "💻 System Resources:"
    echo "  🧠 Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
    echo "  ⚡ CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')%"
    echo "  💾 Disk: $(df -h / | awk 'NR==2 {print $4 " free"}')"
    
    # Docker service status
    echo
    print_color "$BLUE" "🔧 Service Status:"
    if systemctl is-active --quiet docker; then
        print_color "$GREEN" "  ✅ Docker service: Running"
    else
        print_color "$RED" "  ❌ Docker service: Stopped"
    fi
    
    read -p "⏎ Press Enter to continue..."
}

# Main menu
main_menu() {
    while true; do
        print_header
        
        # Show quick status
        if check_docker_installation; then
            local running=$(docker ps -q | wc -l)
            local total=$(docker ps -a -q | wc -l)
            echo -e "${GREEN}🐳 Docker Status: ${running}/${total} containers running${NC}"
        else
            echo -e "${RED}❌ Docker not installed${NC}"
        fi
        
        echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}                      MAIN MENU                            ${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
        echo
        
        echo -e "${WHITE}📦 CONTAINER MANAGEMENT${NC}"
        echo "  1) 📋 List containers"
        echo "  2) 🚀 Run new container"
        echo "  3) ▶️  Start container"
        echo "  4) ⏹️  Stop container"
        echo "  5) 🗑️  Remove container"
        echo "  6) 📝 View logs"
        echo "  7) 💻 Execute command"
        
        echo -e "\n${WHITE}🖼️ IMAGE MANAGEMENT${NC}"
        echo "  8) 📦 List images"
        echo "  9) 🔨 Build image"
        echo "  10) 🗑️ Remove images"
        
        echo -e "\n${WHITE}📊 SYSTEM & MONITORING${NC}"
        echo "  11) 📈 Monitor resources"
        echo "  12) 🧹 Clean system"
        echo "  13) 📊 Docker info"
        echo "  14) 💾 Backup & Restore"
        
        echo -e "\n${WHITE}⚙️ DOCKER COMPOSE${NC}"
        echo "  15) 📦 Manage Compose"
        
        echo -e "\n${WHITE}🔧 INSTALLATION & SETUP${NC}"
        echo "  16) 🚀 Install Docker"
        echo "  17) 📦 Install Docker Compose"
        echo "  18) 📊 System status"
        echo "  19) ⚡ Quick commands"
        
        echo -e "\n${WHITE}📋 OTHER${NC}"
        echo "  20) 🔄 Restart Docker service"
        echo "  0) 👋 Exit"
        
        echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${NC}"
        
        read -p "🎯 Select option (0-20): " choice
        
        case $choice in
            1) list_containers ;;
            2) run_container ;;
            3) start_container ;;
            4) stop_container ;;
            5) remove_container ;;
            6) view_logs ;;
            7) exec_command ;;
            8) list_images ;;
            9) build_image ;;
            10) remove_images ;;
            11) monitor_resources ;;
            12) clean_system ;;
            13) show_docker_info ;;
            14) backup_restore ;;
            15) manage_compose ;;
            16) install_docker ;;
            17) install_docker_compose ;;
            18) show_system_status ;;
            19) show_quick_commands ;;
            20)
                print_color "$BLUE" "🔄 Restarting Docker service..."
                sudo systemctl restart docker
                print_color "$GREEN" "✅ Docker service restarted!"
                sleep 2
                ;;
            0)
                print_header
                print_color "$GREEN" "👋 Goodbye! Happy Dockering! 🐳"
                echo
                exit 0
                ;;
            *)
                print_color "$RED" "❌ Invalid option!"
                sleep 1
                ;;
        esac
        
        if [[ "$choice" != "0" ]]; then
            echo
            read -p "⏎ Press Enter to continue..."
        fi
    done
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_color "$YELLOW" "⚠️  Warning: Running as root. Some operations may not work correctly."
        sleep 2
    fi
}

# Main function
main() {
    # Check if running in terminal
    if [[ ! -t 0 ]]; then
        print_color "$RED" "❌ This script must be run in a terminal!"
        exit 1
    fi
    
    # Check root
    check_root
    
    # Start main menu
    main_menu
}

# Run main function
main
