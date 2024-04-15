#!/bin/bash
# This script sets up a Kubernetes container runtime environment on RHEL 9 using Containerd.
# It configures necessary kernel modules, sysctl parameters, and installs the latest versions of containerd and runc.

# Check for RHEL 9 using hostnamectl command
MYOS=$(hostnamectl | awk '/Operating/ { print $3 }')
if [ "$MYOS" != "RedHatEnterprise" ]; then
    echo "This script is only for RHEL 9."
    exit 1
fi

# Determine the platform architecture (amd64 or arm64)
ARCH=$(arch)
case $ARCH in
    aarch64) PLATFORM=arm64 ;;
    x86_64) PLATFORM=amd64 ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Install jq for processing JSON
sudo dnf install -y jq

# Load necessary kernel modules and ensure they auto-load on boot
sudo tee /etc/modules-load.d/containerd.conf > /dev/null <<EOF
overlay
br_netfilter
EOF

# Load modules immediately
sudo modprobe overlay
sudo modprobe br_netfilter

# Set up required sysctl parameters for networking
sudo tee /etc/sysctl.d/99-kubernetes-cri.conf > /dev/null <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl parameters without requiring a reboot
sudo sysctl --system

# Install the latest version of Containerd from GitHub releases
CONTAINERD_VERSION=$(curl -s https://api.github.com/repos/containerd/containerd/releases/latest | jq -r '.tag_name')
CONTAINERD_VERSION=${CONTAINERD_VERSION#v} # Strip leading 'v' from version tag if present
wget https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-${PLATFORM}.tar.gz
sudo tar -xvf containerd-${CONTAINERD_VERSION}-linux-${PLATFORM}.tar.gz -C /usr/local

# Create containerd configuration file with recommended settings
sudo mkdir -p /etc/containerd
sudo tee /etc/containerd/config.toml > /dev/null <<TOML
version = 2
[plugins]
  [plugins."io.containerd.grpc.v1.cri"]
    [plugins."io.containerd.grpc.v1.cri".containerd]
      discard_unpacked_layers = true
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
          runtime_type = "io.containerd.runc.v2"
          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
            SystemdCgroup = true
TOML

# Install the latest version of runc from GitHub releases
RUNC_VERSION=$(curl -s https://api.github.com/repos/opencontainers/runc/releases/latest | jq -r '.tag_name')
wget https://github.com/opencontainers/runc/releases/download/${RUNC_VERSION}/runc.${PLATFORM}
sudo install -m 755 runc.${PLATFORM} /usr/local/sbin/runc

# Setup systemd service for containerd and start it
wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
sudo mv containerd.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now containerd

# Script completion
echo "Container runtime setup is complete."
touch /tmp/container.txt
exit 0
