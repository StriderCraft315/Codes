#!/bin/bash

# ================= COLORS =================
G="\e[32m"; R="\e[31m"; Y="\e[33m"
C="\e[36m"; W="\e[97m"; N="\e[0m"

# ================= ROOT CHECK =================
if [ "$EUID" -ne 0 ]; then
  echo -e "${R}❌ Please run as root${N}"
  exit 1
fi

# ================= DOCKER CHECK =================
if ! command -v docker &>/dev/null; then
  echo -e "${Y}🐳 Docker not found. Installing...${N}"
  apt update -y && apt install -y docker.io
  systemctl enable --now docker
fi

# ================= MAIN MENU =================
clear
echo -e "${C}════════════ DOCKER SYSTEM MENU ════════════${N}"
echo -e "${G}1) Create Container${N}"
echo -e "${Y}2) Exit${N}"
read -p "Choose [1-2]: " MAIN

[ "$MAIN" = "2" ] && exit 0
[ "$MAIN" != "1" ] && echo "Invalid choice" && exit 1

# ================= INPUT =================
read -p "Container name [sys_container]: " NAME
NAME=${NAME:-sys_container}

read -p "RAM in GB [2]: " RAM
RAM=${RAM:-2}

read -p "CPU cores [1]: " CPU
CPU=${CPU:-1}

read -p "SSD size in GB [20]: " SSD
SSD=${SSD:-20}

read -p "Port mapping (example 8080:80) [skip]: " PORT

# ================= IMAGE =================
IMAGE="jrei/systemd-ubuntu:22.04"
echo -e "${Y}[*] Pulling image if required...${N}"
docker pull $IMAGE

# ================= STORAGE AUTO DETECT =================
STORAGE_OPT=""
FS_TYPE=$(docker info 2>/dev/null | grep "Backing Filesystem" | awk '{print $3}')

if [ "$FS_TYPE" = "xfs" ]; then
  STORAGE_OPT="--storage-opt size=${SSD}G"
  echo -e "${G}[✓] XFS detected → SSD limit enabled (${SSD}G)${N}"
else
  echo -e "${Y}[!] Filesystem: ${FS_TYPE:-unknown}${N}"
  echo -e "${Y}[!] SSD hard limit not supported → skipping disk limit${N}"
fi

# ================= CLEAN OLD =================
docker rm -f "$NAME" &>/dev/null
docker volume create ${NAME}-data &>/dev/null

# ================= BUILD RUN CMD =================
RUN_CMD="docker run -dit \
--name $NAME \
--hostname $NAME \
--privileged \
--cgroupns=host \
--memory ${RAM}g \
--cpus $CPU \
$STORAGE_OPT \
-v /sys/fs/cgroup:/sys/fs/cgroup:rw \
-v ${NAME}-data:/data \
--tmpfs /run \
--tmpfs /run/lock \
--tmpfs /tmp \
--restart unless-stopped"

[ -n "$PORT" ] && RUN_CMD="$RUN_CMD -p $PORT"

RUN_CMD="$RUN_CMD $IMAGE /sbin/init"

# ================= CREATE =================
clear
echo -e "${C}════════════ CONTAINER CREATION ════════════${N}"
echo -e "${W}Running command:${N}"
echo "$RUN_CMD"
echo

eval $RUN_CMD

# ================= RESULT =================
if [ $? -eq 0 ]; then
  echo -e "${G}[✓] Container created successfully${N}"

  if [ -z "$STORAGE_OPT" ]; then
    echo -e "${C}[*] Creating logical ${SSD}G disk inside /data${N}"
    docker exec "$NAME" bash -c "
      fallocate -l ${SSD}G /data/ssd.img &&
      mkfs.ext4 /data/ssd.img &&
      mkdir -p /mnt/ssd &&
      mount /data/ssd.img /mnt/ssd
    " 2>/dev/null

    echo -e "${G}[✓] Logical SSD mounted at /mnt/ssd${N}"
  fi

  echo -e "${C}Entering container system...${N}"
  sleep 2
  docker exec -it "$NAME" bash
else
  echo -e "${R}[✗] Container creation failed${N}"
fi
