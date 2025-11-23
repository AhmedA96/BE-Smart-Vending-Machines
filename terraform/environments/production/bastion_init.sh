#!/bin/bash
# Bastion Host Initialization Script
# Sets up SSH and basic security

set -e

echo "Initializing bastion host..."

# Update system
apt-get update
apt-get upgrade -y

# Install essential packages
apt-get install -y \
  curl \
  wget \
  git \
  ssh \
  openssh-server \
  openssh-client \
  net-tools \
  htop \
  awscli \
  jq

# Configure SSH hardening
echo "Configuring SSH..."
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
echo "AllowUsers ubuntu" >> /etc/ssh/sshd_config

# Restart SSH
systemctl restart ssh

# CloudWatch Logs
apt-get install -y awscloudwatch

echo "Bastion host initialized successfully"
