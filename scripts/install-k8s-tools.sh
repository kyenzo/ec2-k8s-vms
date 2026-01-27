#!/bin/bash
# Ubuntu 22.04 Prerequisites Installation Script
# For running Vagrant + libvirt/KVM + Ansible Kubernetes cluster
# This script runs automatically via cloud-init on instance creation

set -e

LOG_FILE="/var/log/install-k8s-tools.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "============================================"
echo "Installing prerequisites for K8s cluster"
echo "Ubuntu 22.04 + Vagrant + libvirt/KVM + Ansible"
echo "Started at: $(date)"
echo "============================================"

# Update system
echo "[1/7] Updating system packages..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# Install KVM and libvirt
echo "[2/7] Installing KVM and libvirt..."
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    qemu-kvm \
    libvirt-daemon-system \
    libvirt-clients \
    bridge-utils \
    virtinst \
    virt-manager \
    libguestfs-tools \
    libosinfo-bin

# Start and enable libvirt
echo "[3/7] Enabling libvirt service..."
systemctl enable --now libvirtd

# Add ubuntu user to libvirt and kvm groups
echo "[4/7] Adding ubuntu user to libvirt and kvm groups..."
usermod -aG libvirt ubuntu
usermod -aG kvm ubuntu

# Install Vagrant
echo "[5/7] Installing Vagrant..."
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y vagrant

# Install vagrant-libvirt plugin dependencies
echo "[6/7] Installing vagrant-libvirt plugin dependencies..."
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential \
    libxslt-dev \
    libxml2-dev \
    libvirt-dev \
    zlib1g-dev \
    ruby-dev \
    ruby-libvirt \
    ebtables \
    dnsmasq-base

# Install the vagrant-libvirt plugin as ubuntu user
echo "[6.5/7] Installing vagrant-libvirt plugin..."
sudo -u ubuntu vagrant plugin install vagrant-libvirt

# Set libvirt as default provider for ubuntu user
echo "[6.75/7] Setting libvirt as default Vagrant provider..."
sudo -u ubuntu bash -c "echo 'export VAGRANT_DEFAULT_PROVIDER=libvirt' >> /home/ubuntu/.bashrc"

# Install Ansible
echo "[7/7] Installing Ansible..."
DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common
add-apt-repository --yes --update ppa:ansible/ansible
DEBIAN_FRONTEND=noninteractive apt-get install -y ansible

# Install kubectl
echo "[Bonus 1/3] Installing kubectl..."
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y kubectl

# Install useful utilities
echo "[Bonus 2/3] Installing additional utilities..."
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    git \
    curl \
    wget \
    vim \
    htop \
    net-tools \
    jq \
    unzip

# Install Docker (useful for development)
echo "[Bonus 3/3] Installing Docker..."
mkdir -p /usr/share/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
usermod -aG docker ubuntu
systemctl enable docker
systemctl start docker

# Verify installations
echo ""
echo "============================================"
echo "Verifying installations..."
echo "============================================"
echo "KVM: $(virsh --version)"
echo "Vagrant: $(vagrant --version)"
echo "Vagrant-libvirt: $(sudo -u ubuntu vagrant plugin list | grep libvirt || echo 'Plugin installation pending')"
echo "Ansible: $(ansible --version | head -1)"
echo "kubectl: $(kubectl version --client 2>/dev/null | head -1)"
echo "Docker: $(docker --version)"

# Create a welcome message
cat > /etc/motd << 'EOF'
============================================
  Kubernetes VMs Development Instance
============================================

Installed tools:
  - KVM/libvirt (virtualization)
  - Vagrant + vagrant-libvirt plugin
  - Ansible (automation)
  - kubectl (Kubernetes CLI)
  - Docker (containerization)

Installation log: /var/log/install-k8s-tools.log

Quick Start:
  1. Clone your Ansible/Vagrant repo
  2. Run: vagrant up
  3. Configure K8s with Ansible playbooks

Note: User 'ubuntu' has been added to:
  - libvirt group (for VM management)
  - kvm group (for hardware virtualization)
  - docker group (for Docker access)

============================================
EOF

echo ""
echo "============================================"
echo "Installation complete!"
echo "Completed at: $(date)"
echo "============================================"
echo ""
echo "All tools have been installed and configured."
echo "Installation log saved to: $LOG_FILE"
echo ""
