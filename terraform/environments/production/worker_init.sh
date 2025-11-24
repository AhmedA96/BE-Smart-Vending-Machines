#!/bin/bash
# Worker Server Initialization Script
# Sets up Docker and prepares for Kamal job deployment
# This runs on EC2 instance startup to configure the worker

set -e

echo "=========================================="
echo "Initializing worker server..."
echo "Environment: ${environment}"
echo "Region: ${aws_region}"
echo "=========================================="

# Log all output
exec > >(tee -a /var/log/worker-init.log)
exec 2>&1

# Update system packages
echo "[1/5] Updating system packages..."
apt-get update
apt-get upgrade -y

# Install required dependencies
echo "[2/5] Installing dependencies..."
apt-get install -y \
  curl \
  wget \
  git \
  ca-certificates \
  gnupg \
  lsb-release \
  apt-transport-https \
  software-properties-common \
  jq \
  awscli

# Install Docker
echo "[3/5] Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh

# Add ubuntu user to docker group (required for Kamal deployment)
echo "[4/5] Configuring Docker permissions..."
usermod -aG docker ubuntu

# Start Docker daemon
systemctl enable docker
systemctl start docker

# Wait for Docker daemon to be ready
echo "Waiting for Docker daemon to be ready..."
for i in {1..30}; do
  if docker info &>/dev/null; then
    echo "Docker daemon is ready"
    break
  fi
  echo "Waiting... ($i/30)"
  sleep 1
done

# Verify Docker installation
echo "[5/5] Verifying Docker installation..."
docker --version

echo "=========================================="
echo "Worker server initialization complete!"
echo "Docker is ready for Kamal deployment"
echo "=========================================="
