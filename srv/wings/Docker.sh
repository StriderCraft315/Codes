#!/bin/bash
set -e

echo "========================================"
echo "   DOCKER AUTO INSTALL (STABLE)"
echo "========================================"

# Root check
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root"
  exit 1
fi

# Detect OS
. /etc/os-release
OS=$ID
VER=$VERSION_CODENAME

echo "✔ Detected OS: $OS ($VER)"

# Update system
echo "🔄 Updating system..."
apt update -y

# Remove broken docker repo if exists
echo "🧹 Cleaning old Docker repos..."
rm -f /etc/apt/sources.list.d/docker.list
rm -f /etc/apt/keyrings/docker.*
apt clean

# Install required packages
apt install -y ca-certificates curl gnupg

# Install Docker (official method)
echo "🐳 Installing Docker (official)..."
curl -fsSL https://get.docker.com | bash

# Enable Docker
systemctl enable --now docker

# Verify
echo "========================================"
docker --version
echo "========================================"

echo "✅ Docker Installed Successfully"
echo "➡ Test: docker run hello-world"
