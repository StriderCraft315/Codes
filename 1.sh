#!/bin/bash

# ==============================
# Enhanced Docker Manager with UI
# ==============================

set -euo pipefail

# ===== Colors and Styles =====
BG_BLUE="\e[44m"
BG_GREEN="\e[42m"
BG_RED="\e[41m"
BG_YELLOW="\e[43m"
BG_CYAN="\e[46m"
BG_MAGENTA="\e[45m"

FG_BLACK="\e[30m"
FG_WHITE="\e[97m"
FG_GREEN="\e[32m"
FG_RED="\e[31m"
FG_YELLOW="\e[33m"
FG_CYAN="\e[36m"
FG_MAGENTA="\e[35m"
FG_BLUE="\e[34m"

BOLD="\e[1m"
DIM="\e[2m"
ITALIC="\e[3m"
UNDERLINE="\e[4m"
BLINK="\e[5m"
REVERSE="\e[7m"
HIDDEN="\e[8m"

RESET="\e[0m"

# Box drawing characters
BOX_HORIZ="─"
BOX_VERT="│"
BOX_CORNER_TL="┌"
BOX_CORNER_TR="┐"
BOX_CORNER_BL="└"
BOX_CORNER_BR="┘"
BOX_T="┬"
BOX_T_INV="┴"
BOX_CROSS="┼"
BOX_ARROW_R="▶"
BOX_ARROW_L="◀"

# ===== Functions =====
print_header() {
    clear
    echo -e "${BG_CYAN}${FG_BLACK}${BOLD}"
    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║                   🐳 DOCKER MANAGER PRO v2.0                     ║"
    echo "║                   📦 Advanced Image Management                    ║"
    echo "╚════════════════════════════════════════════════════════════════════╝${RESET}"
    echo
}

print_box() {
    local width=$1
    local title=$2
    local color=$3
    local content=$4
    
    echo -e "${color}${BOX_CORNER_TL}"
    for ((i=0; i<width-2; i++)); do echo -n "${BOX_HORIZ}"; done
    echo "${BOX_CORNER_TR}${RESET}"
    
    if [ -n "$title" ]; then
        echo -e "${color}${BOX_VERT}${RESET} ${BOLD}${title}${RESET}"
        echo -e "${color}${BOX_VERT}${RESET}"
    fi
    
    echo -e "${color}${BOX_VERT}${RESET} ${content}"
    
    echo -e "${color}${BOX_VERT}${RESET}"
    echo -e "${color}${BOX_CORNER_BL}"
    for ((i=0; i<width-2; i++)); do echo -n "${BOX_HORIZ}"; done
    echo "${BOX_CORNER_BR}${RESET}"
}

print_status() {
    local type=$1
    local message=$2
    
    case $type in
        "INFO") echo -e "${FG_CYAN}📋 [INFO]${RESET} $message" ;;
        "WARN") echo -e "${FG_YELLOW}⚠️  [WARN]${RESET} $message" ;;
        "ERROR") echo -e "${FG_RED}❌ [ERROR]${RESET} $message" ;;
        "SUCCESS") echo -e "${FG_GREEN}✅ [SUCCESS]${RESET} $message" ;;
        "INPUT") echo -e "${FG_MAGENTA}🎯 [INPUT]${RESET} $message" ;;
        "TITLE") echo -e "${BOLD}${FG_BLUE}📌${RESET} ${FG_CYAN}${message}${RESET}" ;;
        *) echo "[$type] $message" ;;
    esac
}

print_menu_item() {
    local number=$1
    local icon=$2
    local text=$3
    local desc=$4
    
    printf "${FG_CYAN}%2d)${RESET} ${BOLD}${icon} ${text}${RESET}\n" "$number"
    printf "     ${DIM}${desc}${RESET}\n"
}

pause() {
    echo
    read -rp "$(echo -e "${FG_CYAN}⏎${RESET} Press ${BOLD}Enter${RESET} to continue... ")" -n1
    echo
}

loading() {
    local msg=$1
    echo -ne "${FG_CYAN}⏳${RESET} ${msg}"
    for i in {1..3}; do
        echo -ne "."
        sleep 0.2
    done
    echo -e "${FG_GREEN} Done!${RESET}"
}

# ===== Root Check =====
if [ "$EUID" -ne 0 ]; then
    print_header
    print_status "ERROR" "This script requires root privileges"
    echo -e "${FG_YELLOW}🔓 Please run with:${RESET} ${BOLD}sudo -i${RESET}"
    exit 1
fi

# ===== Docker Check =====
check_docker() {
    if ! command -v docker &>/dev/null; then
        print_header
        print_status "WARN" "Docker not found. Installing..."
        echo
        print_box 60 "Docker Installation" "${FG_BLUE}" "This will install Docker and Docker Compose"
        
        read -rp "$(echo -e "${FG_YELLOW}❓${RESET} Proceed with Docker installation? (y/N): ")" -n 1
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            loading "Installing Docker"
            curl -fsSL https://get.docker.com | sh
            systemctl enable --now docker
            loading "Installing Docker Compose"
            apt-get install -y docker-compose-plugin
            print_status "SUCCESS" "Docker installed successfully!"
            pause
        else
            print_status "ERROR" "Docker is required for this script"
            exit 1
        fi
    fi
}

# ===== Container Operations =====
list_containers() {
    print_header
    print_status "INFO" "Listing all containers"
    echo
    
    local running=$(docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | head -1)
    local stopped=$(docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | head -1)
    
    echo -e "${BOLD}${FG_GREEN}🚀 Running Containers:${RESET}"
    if [ $(docker ps -q | wc -l) -gt 0 ]; then
        docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
    else
        echo -e "${DIM}No running containers${RESET}"
    fi
    
    echo
    echo -e "${BOLD}${FG_YELLOW}💤 Stopped Containers:${RESET}"
    if [ $(docker ps -a -q | wc -l) -gt $(docker ps -q | wc -l) ]; then
        docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | tail -n +2
    else
        echo -e "${DIM}No stopped containers${RESET}"
    fi
    
    echo
    echo -e "${BOLD}📊 Statistics:${RESET}"
    echo -e "  Total: $(docker ps -a -q | wc -l) containers"
    echo -e "  Running: $(docker ps -q | wc -l) containers"
    echo -e "  Stopped: $(($(docker ps -a -q | wc -l) - $(docker ps -q | wc -l))) containers"
}

start_container() {
    print_header
    print_status "INFO" "Starting a container"
    echo
    
    local containers=($(docker ps -a --format "{{.Names}}" | sort))
    if [ ${#containers[@]} -eq 0 ]; then
        print_status "WARN" "No containers found"
        pause
        return
    fi
    
    echo -e "${BOLD}Available containers:${RESET}"
    for i in "${!containers[@]}"; do
        local status=$(docker inspect -f '{{.State.Status}}' "${containers[$i]}")
        local color="${FG_RED}"
        [[ "$status" == "running" ]] && color="${FG_GREEN}"
        printf "  ${FG_CYAN}%2d)${RESET} ${color}%-20s${RESET} [%s]\n" $((i+1)) "${containers[$i]}" "$status"
    done
    
    echo
    read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Select container (number or name): ")" choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#containers[@]} ]; then
        local container="${containers[$((choice-1))]}"
    else
        local container="$choice"
    fi
    
    loading "Starting container: $container"
    if docker start "$container" &>/dev/null; then
        print_status "SUCCESS" "Container '$container' started successfully!"
    else
        print_status "ERROR" "Failed to start container '$container'"
    fi
}

stop_container() {
    print_header
    print_status "INFO" "Stopping a container"
    echo
    
    local containers=($(docker ps --format "{{.Names}}" | sort))
    if [ ${#containers[@]} -eq 0 ]; then
        print_status "WARN" "No running containers found"
        pause
        return
    fi
    
    echo -e "${BOLD}Running containers:${RESET}"
    for i in "${!containers[@]}"; do
        printf "  ${FG_CYAN}%2d)${RESET} %-20s\n" $((i+1)) "${containers[$i]}"
    done
    
    echo
    read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Select container (number or name): ")" choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#containers[@]} ]; then
        local container="${containers[$((choice-1))]}"
    else
        local container="$choice"
    fi
    
    loading "Stopping container: $container"
    if docker stop "$container" &>/dev/null; then
        print_status "SUCCESS" "Container '$container' stopped successfully!"
    else
        print_status "ERROR" "Failed to stop container '$container'"
    fi
}

restart_container() {
    print_header
    print_status "INFO" "Restarting a container"
    echo
    
    local containers=($(docker ps -a --format "{{.Names}}" | sort))
    if [ ${#containers[@]} -eq 0 ]; then
        print_status "WARN" "No containers found"
        pause
        return
    fi
    
    echo -e "${BOLD}Available containers:${RESET}"
    for i in "${!containers[@]}"; do
        local status=$(docker inspect -f '{{.State.Status}}' "${containers[$i]}")
        local color="${FG_RED}"
        [[ "$status" == "running" ]] && color="${FG_GREEN}"
        printf "  ${FG_CYAN}%2d)${RESET} ${color}%-20s${RESET} [%s]\n" $((i+1)) "${containers[$i]}" "$status"
    done
    
    echo
    read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Select container (number or name): ")" choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#containers[@]} ]; then
        local container="${containers[$((choice-1))]}"
    else
        local container="$choice"
    fi
    
    loading "Restarting container: $container"
    if docker restart "$container" &>/dev/null; then
        print_status "SUCCESS" "Container '$container' restarted successfully!"
    else
        print_status "ERROR" "Failed to restart container '$container'"
    fi
}

delete_container() {
    print_header
    print_status "WARN" "Deleting a container"
    echo
    
    local containers=($(docker ps -a --format "{{.Names}}" | sort))
    if [ ${#containers[@]} -eq 0 ]; then
        print_status "WARN" "No containers found"
        pause
        return
    fi
    
    echo -e "${BOLD}Available containers:${RESET}"
    for i in "${!containers[@]}"; do
        local status=$(docker inspect -f '{{.State.Status}}' "${containers[$i]}")
        local color="${FG_RED}"
        [[ "$status" == "running" ]] && color="${FG_GREEN}"
        printf "  ${FG_CYAN}%2d)${RESET} ${color}%-20s${RESET} [%s]\n" $((i+1)) "${containers[$i]}" "$status"
    done
    
    echo
    read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Select container (number or name): ")" choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#containers[@]} ]; then
        local container="${containers[$((choice-1))]}"
    else
        local container="$choice"
    fi
    
    echo -e "\n${FG_RED}⚠️  WARNING:${RESET} This will delete container '${BOLD}$container${RESET}'"
    read -rp "$(echo -e "${FG_YELLOW}❓${RESET} Are you sure? Type 'yes' to confirm: ")" confirm
    
    if [[ "$confirm" == "yes" ]]; then
        loading "Deleting container: $container"
        if docker rm -f "$container" &>/dev/null; then
            print_status "SUCCESS" "Container '$container' deleted successfully!"
        else
            print_status "ERROR" "Failed to delete container '$container'"
        fi
    else
        print_status "INFO" "Deletion cancelled"
    fi
}

view_logs() {
    print_header
    print_status "INFO" "Viewing container logs"
    echo
    
    local containers=($(docker ps -a --format "{{.Names}}" | sort))
    if [ ${#containers[@]} -eq 0 ]; then
        print_status "WARN" "No containers found"
        pause
        return
    fi
    
    echo -e "${BOLD}Available containers:${RESET}"
    for i in "${!containers[@]}"; do
        local status=$(docker inspect -f '{{.State.Status}}' "${containers[$i]}")
        local color="${FG_RED}"
        [[ "$status" == "running" ]] && color="${FG_GREEN}"
        printf "  ${FG_CYAN}%2d)${RESET} ${color}%-20s${RESET} [%s]\n" $((i+1)) "${containers[$i]}" "$status"
    done
    
    echo
    read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Select container (number or name): ")" choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#containers[@]} ]; then
        local container="${containers[$((choice-1))]}"
    else
        local container="$choice"
    fi
    
    print_status "INFO" "Showing logs for '$container' (Press Ctrl+C to exit)"
    echo -e "${DIM}══════════════════════════════════════════════════════════════${RESET}"
    
    if docker logs -f "$container"; then
        echo -e "${DIM}══════════════════════════════════════════════════════════════${RESET}"
        echo -e "${FG_CYAN}📋 Log stream ended${RESET}"
    fi
}

quick_run() {
    print_header
    print_status "INFO" "Quick Run - Auto Port Detect"
    echo
    
    read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Image name (e.g., nginx, redis:alpine): ")" img
    
    if [ -z "$img" ]; then
        print_status "ERROR" "Image name cannot be empty"
        pause
        return
    fi
    
    local cname="ct-$(date +%H%M%S)"
    
    print_box 60 "Quick Run Configuration" "${FG_BLUE}" \
        "Image: ${BOLD}$img${RESET}\n"\
        "Name: ${BOLD}$cname${RESET}\n"\
        "Auto-port detection: ${BOLD}Enabled${RESET}"
    
    loading "Pulling image: $img"
    if ! docker pull "$img" &>/dev/null; then
        print_status "ERROR" "Failed to pull image '$img'"
        pause
        return
    fi
    
    # Try to get exposed ports
    local ports=$(docker inspect --format='{{range $p,$v := .Config.ExposedPorts}}{{println $p}}{{end}}' "$img" 2>/dev/null | head -5)
    
    local CMD="docker run -d --name $cname --restart unless-stopped"
    
    if [ -n "$ports" ]; then
        echo -e "\n${FG_GREEN}🔍 Found exposed ports:${RESET}"
        for p in $ports; do
            local port_num=$(echo "$p" | cut -d'/' -f1)
            echo -e "  ${FG_CYAN}➜${RESET} Port $port_num"
            CMD="$CMD -p $port_num:$port_num"
        done
    else
        echo -e "\n${FG_YELLOW}⚠️  No exposed ports found, using random port mapping${RESET}"
        CMD="$CMD -P"
    fi
    
    CMD="$CMD $img"
    
    echo -e "\n${BOLD}Command to execute:${RESET}"
    echo -e "${DIM}$CMD${RESET}"
    echo
    
    read -rp "$(echo -e "${FG_YELLOW}❓${RESET} Proceed? (y/N): ")" -n 1
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        loading "Creating container: $cname"
        if eval "$CMD" &>/dev/null; then
            print_status "SUCCESS" "Container '$cname' created and started successfully!"
            echo -e "${FG_CYAN}📊 Container info:${RESET}"
            docker ps --filter "name=$cname" --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
        else
            print_status "ERROR" "Failed to create container"
        fi
    else
        print_status "INFO" "Operation cancelled"
    fi
}

# ===== Image Management Functions =====
list_images() {
    print_header
    print_status "TITLE" "📦 Docker Image Management"
    echo
    
    # Get image statistics
    local total_images=$(docker images -q | wc -l)
    local total_size=$(docker system df --format '{{.ImagesSize}}' 2>/dev/null || echo "N/A")
    
    echo -e "${BOLD}📊 Image Statistics:${RESET}"
    echo -e "  📦 Total Images: ${BOLD}$total_images${RESET}"
    echo -e "  📏 Total Size: ${BOLD}$total_size${RESET}"
    echo
    
    echo -e "${BOLD}🖼️  Available Images:${RESET}"
    if [ $total_images -eq 0 ]; then
        echo -e "${DIM}No Docker images found. Pull some images first.${RESET}"
    else
        docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}\t{{.CreatedSince}}" | head -20
        
        if [ $total_images -gt 20 ]; then
            echo -e "\n${FG_YELLOW}⚠️  Showing first 20 of $total_images images${RESET}"
        fi
    fi
}

pull_image() {
    print_header
    print_status "INFO" "Pull Docker Image"
    echo
    
    print_box 60 "Quick Pull Options" "${FG_BLUE}" \
        "Popular images you can pull quickly:\n"\
        "1) nginx:alpine (Lightweight web server)\n"\
        "2) redis:alpine (Key-value store)\n"\
        "3) postgres:alpine (Database)\n"\
        "4) mysql:latest (MySQL database)\n"\
        "5) node:alpine (Node.js runtime)\n"\
        "6) python:alpine (Python runtime)\n"\
        "7) ubuntu:latest (Ubuntu base image)\n"\
        "8) alpine:latest (Minimal Linux)\n"\
        "9) traefik:latest (Reverse proxy)\n"\
        "10) Custom image (enter any name)"
    
    echo
    read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Select option (1-10): ")" pull_choice
    
    local image_name=""
    
    case $pull_choice in
        1) image_name="nginx:alpine" ;;
        2) image_name="redis:alpine" ;;
        3) image_name="postgres:alpine" ;;
        4) image_name="mysql:latest" ;;
        5) image_name="node:alpine" ;;
        6) image_name="python:alpine" ;;
        7) image_name="ubuntu:latest" ;;
        8) image_name="alpine:latest" ;;
        9) image_name="traefik:latest" ;;
        10)
            read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Enter image name (e.g., nginx:1.21): ")" image_name
            ;;
        *)
            print_status "ERROR" "Invalid option"
            return
            ;;
    esac
    
    if [ -z "$image_name" ]; then
        print_status "ERROR" "Image name cannot be empty"
        return
    fi
    
    # Check if image already exists
    if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${image_name}$"; then
        print_status "WARN" "Image '$image_name' already exists locally"
        read -rp "$(echo -e "${FG_YELLOW}❓${RESET} Pull latest version anyway? (y/N): ")" -n 1
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && return
    fi
    
    loading "Pulling image: $image_name"
    if docker pull "$image_name"; then
        print_status "SUCCESS" "Image '$image_name' pulled successfully!"
        
        # Show image details
        echo -e "\n${BOLD}📋 Image Details:${RESET}"
        docker images "$image_name" --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}\t{{.CreatedSince}}"
    else
        print_status "ERROR" "Failed to pull image '$image_name'"
    fi
}

search_images() {
    print_header
    print_status "INFO" "Search Docker Hub Images"
    echo
    
    read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Search term (e.g., nginx, database, web): ")" search_term
    
    if [ -z "$search_term" ]; then
        print_status "ERROR" "Search term cannot be empty"
        return
    fi
    
    loading "Searching Docker Hub for: $search_term"
    
    # Use docker search with formatting
    echo -e "\n${BOLD}🔍 Search Results:${RESET}"
    echo -e "${DIM}══════════════════════════════════════════════════════════════${RESET}"
    
    # Try to search with docker command
    if docker search --limit 10 "$search_term" 2>/dev/null | head -11; then
        echo -e "${DIM}══════════════════════════════════════════════════════════════${RESET}"
        echo -e "\n${FG_CYAN}💡 Tip:${RESET} Use 'pull image' option to download any of these images"
    else
        print_status "ERROR" "Failed to search Docker Hub. Check your internet connection."
    fi
}

remove_image() {
    print_header
    print_status "WARN" "Remove Docker Image"
    echo
    
    local images=($(docker images --format "{{.Repository}}:{{.Tag}}" | sort | grep -v "<none>"))
    
    if [ ${#images[@]} -eq 0 ]; then
        print_status "WARN" "No images found"
        pause
        return
    fi
    
    echo -e "${BOLD}📦 Available Images:${RESET}"
    for i in "${!images[@]}"; do
        local size=$(docker images --format "{{.Size}}" "${images[$i]}" | head -1)
        printf "  ${FG_CYAN}%2d)${RESET} %-40s ${DIM}[%s]${RESET}\n" $((i+1)) "${images[$i]}" "$size"
    done
    
    echo
    read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Select image to remove (number or name): ")" choice
    
    local image_name=""
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#images[@]} ]; then
        image_name="${images[$((choice-1))]}"
    else
        image_name="$choice"
    fi
    
    # Check if image is being used by containers
    local used_by=$(docker ps -a --filter "ancestor=$image_name" --format "{{.Names}}" | tr '\n' ' ')
    
    if [ -n "$used_by" ]; then
        echo -e "\n${FG_RED}⚠️  WARNING:${RESET} Image is used by containers: ${BOLD}$used_by${RESET}"
        read -rp "$(echo -e "${FG_YELLOW}❓${RESET} Remove anyway? This won't delete containers. (y/N): ")" -n 1
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && return
    fi
    
    echo -e "\n${FG_RED}⚠️  WARNING:${RESET} This will remove image '${BOLD}$image_name${RESET}'"
    read -rp "$(echo -e "${FG_YELLOW}❓${RESET} Are you sure? Type 'yes' to confirm: ")" confirm
    
    if [[ "$confirm" == "yes" ]]; then
        loading "Removing image: $image_name"
        if docker rmi "$image_name"; then
            print_status "SUCCESS" "Image '$image_name' removed successfully!"
        else
            print_status "ERROR" "Failed to remove image. It might be in use."
        fi
    else
        print_status "INFO" "Removal cancelled"
    fi
}

build_image() {
    print_header
    print_status "INFO" "Build Docker Image from Dockerfile"
    echo
    
    echo -e "${FG_YELLOW}📁 Current directory:${RESET} $(pwd)"
    echo
    
    # Check for Dockerfile
    if [ ! -f "Dockerfile" ] && [ ! -f "dockerfile" ]; then
        print_status "WARN" "No Dockerfile found in current directory"
        
        echo -e "\n${BOLD}📝 Create a sample Dockerfile?${RESET}"
        read -rp "$(echo -e "${FG_YELLOW}❓${RESET} Create sample Dockerfile? (y/N): ")" -n 1
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cat > Dockerfile << 'EOF'
# Sample Dockerfile
FROM alpine:latest

# Install packages
RUN apk add --no-cache \
    nginx \
    curl

# Create working directory
WORKDIR /app

# Copy files
COPY . .

# Expose port
EXPOSE 80

# Start command
CMD ["nginx", "-g", "daemon off;"]
EOF
            print_status "SUCCESS" "Sample Dockerfile created!"
        else
            return
        fi
    fi
    
    local dockerfile_name="Dockerfile"
    [ -f "dockerfile" ] && dockerfile_name="dockerfile"
    
    echo -e "${FG_GREEN}✅ Found $dockerfile_name${RESET}"
    echo -e "\n${BOLD}📄 Dockerfile preview (first 10 lines):${RESET}"
    echo -e "${DIM}══════════════════════════════════════════════════════════════${RESET}"
    head -10 "$dockerfile_name"
    echo -e "${DIM}══════════════════════════════════════════════════════════════${RESET}"
    
    read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Image name (e.g., myapp:v1): ")" image_name
    read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Image tag (default: latest): ")" image_tag
    image_tag=${image_tag:-latest}
    
    if [ -z "$image_name" ]; then
        image_name="myapp:$image_tag"
    elif [[ ! "$image_name" =~ : ]]; then
        image_name="$image_name:$image_tag"
    fi
    
    print_box 60 "Build Configuration" "${FG_BLUE}" \
        "Dockerfile: ${BOLD}$dockerfile_name${RESET}\n"\
        "Image name: ${BOLD}$image_name${RESET}\n"\
        "Context: ${BOLD}$(pwd)${RESET}"
    
    echo
    read -rp "$(echo -e "${FG_YELLOW}❓${RESET} Proceed with build? (y/N): ")" -n 1
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        loading "Building image: $image_name"
        if docker build -t "$image_name" -f "$dockerfile_name" .; then
            print_status "SUCCESS" "Image '$image_name' built successfully!"
            echo -e "\n${BOLD}📋 New Image Details:${RESET}"
            docker images "$image_name" --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}\t{{.CreatedAt}}"
        else
            print_status "ERROR" "Build failed. Check your Dockerfile."
        fi
    else
        print_status "INFO" "Build cancelled"
    fi
}

export_image() {
    print_header
    print_status "INFO" "Export Docker Image to File"
    echo
    
    local images=($(docker images --format "{{.Repository}}:{{.Tag}}" | sort | grep -v "<none>"))
    
    if [ ${#images[@]} -eq 0 ]; then
        print_status "WARN" "No images found"
        pause
        return
    fi
    
    echo -e "${BOLD}📦 Available Images:${RESET}"
    for i in "${!images[@]}"; do
        local size=$(docker images --format "{{.Size}}" "${images[$i]}" | head -1)
        printf "  ${FG_CYAN}%2d)${RESET} %-40s ${DIM}[%s]${RESET}\n" $((i+1)) "${images[$i]}" "$size"
    done
    
    echo
    read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Select image to export (number or name): ")" choice
    
    local image_name=""
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#images[@]} ]; then
        image_name="${images[$((choice-1))]}"
    else
        image_name="$choice"
    fi
    
    # Suggest filename
    local default_filename=$(echo "${image_name//:/_}" | tr '/' '_').tar
    default_filename="${default_filename//\/_/_}"
    
    read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Output file (default: $default_filename): ")" output_file
    output_file=${output_file:-$default_filename}
    
    # Ensure .tar extension
    [[ ! "$output_file" =~ \.tar$ ]] && output_file="$output_file.tar"
    
    print_box 60 "Export Configuration" "${FG_BLUE}" \
        "Image: ${BOLD}$image_name${RESET}\n"\
        "Output: ${BOLD}$output_file${RESET}\n"\
        "Size: $(docker images --format "{{.Size}}" "$image_name" | head -1)"
    
    echo
    read -rp "$(echo -e "${FG_YELLOW}❓${RESET} Export image? (y/N): ")" -n 1
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        loading "Exporting image to: $output_file"
        if docker save "$image_name" -o "$output_file"; then
            local file_size=$(du -h "$output_file" | cut -f1)
            print_status "SUCCESS" "Image exported successfully!"
            echo -e "  📁 File: ${BOLD}$output_file${RESET}"
            echo -e "  📏 Size: ${BOLD}$file_size${RESET}"
            echo -e "  📍 Location: ${BOLD}$(pwd)/$output_file${RESET}"
        else
            print_status "ERROR" "Failed to export image"
        fi
    else
        print_status "INFO" "Export cancelled"
    fi
}

import_image() {
    print_header
    print_status "INFO" "Import Docker Image from File"
    echo
    
    # List .tar files in current directory
    local tar_files=($(ls -1 *.tar 2>/dev/null | head -10))
    
    if [ ${#tar_files[@]} -gt 0 ]; then
        echo -e "${BOLD}📂 Found .tar files:${RESET}"
        for i in "${!tar_files[@]}"; do
            local file_size=$(du -h "${tar_files[$i]}" | cut -f1)
            printf "  ${FG_CYAN}%2d)${RESET} %-40s ${DIM}[%s]${RESET}\n" $((i+1)) "${tar_files[$i]}" "$file_size"
        done
        echo
    fi
    
    read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Input file (.tar) or path: ")" input_file
    
    if [ ! -f "$input_file" ]; then
        print_status "ERROR" "File '$input_file' not found"
        return
    fi
    
    if [[ ! "$input_file" =~ \.tar$ ]]; then
        print_status "WARN" "File doesn't have .tar extension. Continue anyway?"
        read -rp "$(echo -e "${FG_YELLOW}❓${RESET} Continue? (y/N): ")" -n 1
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && return
    fi
    
    read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Image name (optional, leave blank to keep original): ")" image_name
    
    local file_size=$(du -h "$input_file" | cut -f1)
    
    print_box 60 "Import Configuration" "${FG_BLUE}" \
        "Input file: ${BOLD}$input_file${RESET}\n"\
        "File size: ${BOLD}$file_size${RESET}\n"\
        "Image name: ${BOLD}${image_name:-Keep original}${RESET}"
    
    echo
    read -rp "$(echo -e "${FG_YELLOW}❓${RESET} Import image? (y/N): ")" -n 1
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        loading "Importing image from: $input_file"
        
        if [ -n "$image_name" ]; then
            if docker load -i "$input_file" | grep "Loaded image" | sed "s/Loaded image: /docker tag /" | sh && \
               docker tag "$(docker load -i "$input_file" | grep "Loaded image" | cut -d: -f2- | xargs)" "$image_name"; then
                print_status "SUCCESS" "Image imported and tagged as '$image_name'!"
            else
                print_status "ERROR" "Failed to import image"
            fi
        else
            if docker load -i "$input_file"; then
                print_status "SUCCESS" "Image imported successfully!"
            else
                print_status "ERROR" "Failed to import image"
            fi
        fi
    else
        print_status "INFO" "Import cancelled"
    fi
}

image_history() {
    print_header
    print_status "INFO" "Image History and Layers"
    echo
    
    local images=($(docker images --format "{{.Repository}}:{{.Tag}}" | sort | grep -v "<none>"))
    
    if [ ${#images[@]} -eq 0 ]; then
        print_status "WARN" "No images found"
        pause
        return
    fi
    
    echo -e "${BOLD}📦 Available Images:${RESET}"
    for i in "${!images[@]}"; do
        local size=$(docker images --format "{{.Size}}" "${images[$i]}" | head -1)
        printf "  ${FG_CYAN}%2d)${RESET} %-40s ${DIM}[%s]${RESET}\n" $((i+1)) "${images[$i]}" "$size"
    done
    
    echo
    read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Select image to inspect (number or name): ")" choice
    
    local image_name=""
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#images[@]} ]; then
        image_name="${images[$((choice-1))]}"
    else
        image_name="$choice"
    fi
    
    loading "Inspecting image: $image_name"
    
    echo -e "\n${BOLD}📜 Image History:${RESET}"
    echo -e "${DIM}══════════════════════════════════════════════════════════════${RESET}"
    docker history --no-trunc "$image_name" 2>/dev/null || docker history "$image_name"
    echo -e "${DIM}══════════════════════════════════════════════════════════════${RESET}"
    
    echo -e "\n${BOLD}🔍 Image Details:${RESET}"
    docker inspect "$image_name" --format '\
{{- printf "ID: %s\n" .Id -}}\
{{- printf "Created: %s\n" .Created -}}\
{{- printf "Size: %v bytes\n" .Size -}}\
{{- printf "Architecture: %s\n" .Architecture -}}\
{{- printf "OS: %s\n" .Os -}}\
{{- printf "Docker Version: %s\n" .DockerVersion -}}\
{{- range $key, $value := .Config.Labels -}}\
{{- printf "Label: %s=%s\n" $key $value -}}\
{{- end -}}' | head -20
}

clean_dangling_images() {
    print_header
    print_status "WARN" "Clean Dangling Images"
    echo
    
    local dangling_count=$(docker images -f "dangling=true" -q | wc -l)
    
    if [ $dangling_count -eq 0 ]; then
        print_status "INFO" "No dangling images found"
        pause
        return
    fi
    
    echo -e "${BOLD}🗑️  Dangling Images Found:${RESET}"
    docker images -f "dangling=true" --format "table {{.ID}}\t{{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}"
    
    echo -e "\n${FG_RED}⚠️  WARNING:${RESET} This will remove ${BOLD}$dangling_count${RESET} dangling images"
    read -rp "$(echo -e "${FG_YELLOW}❓${RESET} Proceed? (y/N): ")" -n 1
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        loading "Removing dangling images"
        if docker image prune -f; then
            print_status "SUCCESS" "$dangling_count dangling images removed!"
        else
            print_status "ERROR" "Failed to remove dangling images"
        fi
    else
        print_status "INFO" "Cleanup cancelled"
    fi
}

image_menu() {
    while true; do
        print_header
        print_status "TITLE" "📦 Docker Image Management Center"
        echo
        
        # Image statistics
        local total_images=$(docker images -q | wc -l)
        local dangling_count=$(docker images -f "dangling=true" -q | wc -l)
        local total_size=$(docker system df --format '{{.ImagesSize}}' 2>/dev/null || echo "N/A")
        
        echo -e "${BOLD}📊 Quick Stats:${RESET}"
        echo -e "  📦 Total Images: ${BOLD}$total_images${RESET}"
        echo -e "  🗑️  Dangling: ${BOLD}$dangling_count${RESET}"
        echo -e "  📏 Total Size: ${BOLD}$total_size${RESET}"
        echo
        
        # Menu options
        print_menu_item 1 "📋" "List Images" "Show all Docker images"
        print_menu_item 2 "⬇️" "Pull Image" "Download image from Docker Hub"
        print_menu_item 3 "🔍" "Search Images" "Search Docker Hub registry"
        print_menu_item 4 "🗑️" "Remove Image" "Delete a Docker image"
        print_menu_item 5 "🔨" "Build Image" "Build from Dockerfile"
        print_menu_item 6 "📤" "Export Image" "Save image to .tar file"
        print_menu_item 7 "📥" "Import Image" "Load image from .tar file"
        print_menu_item 8 "📜" "Image History" "View image layers and history"
        print_menu_item 9 "🧹" "Clean Dangling" "Remove unused images"
        print_menu_item 10 "🏠" "Back to Main" "Return to main menu"
        
        echo
        read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Select option (1-10): ")" img_opt
        
        case $img_opt in
            1) list_images; pause ;;
            2) pull_image; pause ;;
            3) search_images; pause ;;
            4) remove_image; pause ;;
            5) build_image; pause ;;
            6) export_image; pause ;;
            7) import_image; pause ;;
            8) image_history; pause ;;
            9) clean_dangling_images; pause ;;
            10) return ;;
            *)
                print_status "ERROR" "Invalid option!"
                sleep 1
                ;;
        esac
    done
}

advanced_create() {
    print_header
    print_status "INFO" "Advanced Container Creation"
    echo
    
    # Container name
    local cname="ct-$(date +%H%M%S)"
    read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Container Name (blank for auto: $cname): ")" input_name
    [ -n "$input_name" ] && cname="$input_name"
    
    # Image name
    while true; do
        read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Image Name (required): ")" img
        if [ -n "$img" ]; then
            break
        fi
        print_status "ERROR" "Image name cannot be empty"
    done
    
    # Volumes
    read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Volume mount (e.g., /host:/container): ")" vol
    
    # Environment variables
    read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Environment variables (e.g., KEY=value): ")" env
    
    # Network
    read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Network (blank for bridge): ")" network
    
    # Ports
    read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Port mapping (e.g., 8080:80): ")" ports
    
    # Pull image first
    loading "Pulling image: $img"
    if ! docker pull "$img" &>/dev/null; then
        print_status "ERROR" "Failed to pull image '$img'"
        pause
        return
    fi
    
    # Build command
    local CMD="docker run -d --name $cname --restart unless-stopped"
    
    [ -n "$vol" ] && CMD="$CMD -v $vol"
    [ -n "$env" ] && CMD="$CMD -e $env"
    [ -n "$network" ] && CMD="$CMD --network $network"
    [ -n "$ports" ] && CMD="$CMD -p $ports"
    
    CMD="$CMD $img"
    
    print_box 60 "Advanced Configuration" "${FG_BLUE}" \
        "Container: ${BOLD}$cname${RESET}\n"\
        "Image: ${BOLD}$img${RESET}\n"\
        "Volume: ${BOLD}${vol:-None}${RESET}\n"\
        "Env: ${BOLD}${env:-None}${RESET}\n"\
        "Network: ${BOLD}${network:-bridge}${RESET}\n"\
        "Ports: ${BOLD}${ports:-Auto}${RESET}"
    
    echo -e "\n${BOLD}Command to execute:${RESET}"
    echo -e "${DIM}$CMD${RESET}"
    echo
    
    read -rp "$(echo -e "${FG_YELLOW}❓${RESET} Create container? (y/N): ")" -n 1
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        loading "Creating container: $cname"
        if eval "$CMD" &>/dev/null; then
            print_status "SUCCESS" "Container '$cname' created successfully!"
            echo -e "${FG_CYAN}📊 Container details:${RESET}"
            docker inspect "$cname" --format '\
Name: {{.Name}}\n\
Status: {{.State.Status}}\n\
Image: {{.Config.Image}}\n\
IP: {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}\n\
Ports: {{range $p, $conf := .NetworkSettings.Ports}}{{$p}} {{end}}\n\
Created: {{.Created}}'
        else
            print_status "ERROR" "Failed to create container"
        fi
    else
        print_status "INFO" "Operation cancelled"
    fi
}

docker_stats() {
    print_header
    print_status "INFO" "Docker System Statistics"
    echo
    
    print_box 60 "System Information" "${FG_BLUE}" \
        "Docker Version: $(docker version --format '{{.Server.Version}}')\n"\
        "Containers: $(docker ps -q | wc -l) running, $(docker ps -a -q | wc -l) total\n"\
        "Images: $(docker images -q | wc -l)\n"\
        "Volumes: $(docker volume ls -q | wc -l)\n"\
        "Networks: $(docker network ls -q | wc -l)"
    
    echo
    echo -e "${BOLD}📈 Resource Usage:${RESET}"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}"
    
    echo
    echo -e "${BOLD}🗑️  Disk Usage:${RESET}"
    docker system df --format 'table {{.Type}}\t{{.TotalCount}}\t{{.Size}}\t{{.Reclaimable}}'
}

cleanup_system() {
    print_header
    print_status "WARN" "Docker System Cleanup"
    echo
    
    print_box 60 "Cleanup Options" "${FG_YELLOW}" \
        "1) Remove stopped containers\n"\
        "2) Remove unused images\n"\
        "3) Remove unused volumes\n"\
        "4) Remove unused networks\n"\
        "5) Remove build cache\n"\
        "6) Full cleanup (everything)"
    
    echo
    read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Select option (1-6): ")" cleanup_opt
    
    case $cleanup_opt in
        1)
            loading "Removing stopped containers"
            docker container prune -f
            print_status "SUCCESS" "Stopped containers removed"
            ;;
        2)
            loading "Removing unused images"
            docker image prune -af
            print_status "SUCCESS" "Unused images removed"
            ;;
        3)
            loading "Removing unused volumes"
            docker volume prune -f
            print_status "SUCCESS" "Unused volumes removed"
            ;;
        4)
            loading "Removing unused networks"
            docker network prune -f
            print_status "SUCCESS" "Unused networks removed"
            ;;
        5)
            loading "Removing build cache"
            docker builder prune -f
            print_status "SUCCESS" "Build cache removed"
            ;;
        6)
            loading "Performing full cleanup"
            docker system prune -af --volumes
            print_status "SUCCESS" "Full cleanup completed"
            ;;
        *)
            print_status "ERROR" "Invalid option"
            ;;
    esac
}

# ===== Main Menu =====
main_menu() {
    while true; do
        print_header
        
        # Show quick stats
        local running=$(docker ps -q | wc -l)
        local total=$(docker ps -a -q | wc -l)
        local images=$(docker images -q | wc -l)
        
        echo -e "${FG_CYAN}📊 Quick Stats:${RESET}"
        echo -e "  🐳 Containers: ${BOLD}${FG_GREEN}$running${RESET} running / ${BOLD}$total${RESET} total"
        echo -e "  📦 Images: ${BOLD}$images${RESET}"
        echo
        
        # Menu options
        print_menu_item 1 "📋" "List Containers" "Show all containers with details"
        print_menu_item 2 "🚀" "Start Container" "Start a stopped container"
        print_menu_item 3 "🛑" "Stop Container" "Stop a running container"
        print_menu_item 4 "🔄" "Restart Container" "Restart a container"
        print_menu_item 5 "🗑️" "Delete Container" "Remove a container (with force)"
        print_menu_item 6 "📜" "View Logs" "View container logs in real-time"
        print_menu_item 7 "⚡" "Quick Run" "Auto-detect ports and run container"
        print_menu_item 8 "📦" "Image Manager" "Advanced image management"
        print_menu_item 9 "🔧" "Advanced Create" "Create container with custom options"
        print_menu_item 10 "📈" "System Stats" "Show Docker system statistics"
        print_menu_item 11 "🧹" "Cleanup System" "Remove unused Docker resources"
        print_menu_item 12 "👋" "Exit" "Exit Docker Manager"
        
        echo
        read -rp "$(echo -e "${FG_MAGENTA}🎯${RESET} Select option (1-12): ")" opt
        
        case $opt in
            1) list_containers; pause ;;
            2) start_container; pause ;;
            3) stop_container; pause ;;
            4) restart_container; pause ;;
            5) delete_container; pause ;;
            6) view_logs ;;
            7) quick_run; pause ;;
            8) image_menu ;;
            9) advanced_create; pause ;;
            10) docker_stats; pause ;;
            11) cleanup_system; pause ;;
            12)
                print_header
                echo -e "${FG_GREEN}${BOLD}"
                echo "╔════════════════════════════════════════════════════════════════════╗"
                echo "║                     👋 Goodbye!                                  ║"
                echo "║                 Docker Manager Pro v2.0                          ║"
                echo "╚════════════════════════════════════════════════════════════════════╝"
                echo -e "${RESET}"
                exit 0
                ;;
            *)
                print_status "ERROR" "Invalid option!"
                sleep 1
                ;;
        esac
    done
}

# ===== Main Execution =====
check_docker
main_menu
