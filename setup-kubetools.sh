#!/bin/bash
# This script automates the installation of Kubernetes components (kubeadm, kubelet, kubectl)
# on Ubuntu 20.04 LTS or later.
#
# Prerequisites:
# - This script must be run with sudo to ensure sufficient permissions for installation and configuration tasks.
# - Prior to running this script, the setup-container.sh script must be executed to prepare the system's container runtime.

# Ensuring the script is executed with root privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run with sudo. Exiting."
    exit 3
fi

# Checking if the container runtime setup script has been successfully executed
if [ ! -f /tmp/container.txt ]; then
    echo "Required setup-container.sh script has not been run. Please run it before this script."
    exit 4
fi

# Verify the operating system
MYOS=$(hostnamectl | awk '/Operating/ { print $3 }')
if [ "$MYOS" != "Ubuntu" ]; then
    echo "This script is only designed to run on Ubuntu. Exiting."
    exit 5
fi

# Script begins Kubernetes components installation
echo "Starting the configuration of Kubernetes on Ubuntu..."

# Loading the br_netfilter module which is necessary for the Kubernetes networking model
echo "br_netfilter" | sudo tee /etc/modules-load.d/k8s.conf
echo "Loaded br_netfilter module for Kubernetes networking."

# Updating the package list and installing prerequisites
sudo apt-get update
sudo apt-get install -y apt-transport-https curl
echo "Installed necessary packages for fetching Kubernetes."

# Fetching the latest Kubernetes version to install
KUBEVERSION=$(curl -s https://api.github.com/repos/kubernetes/kubernetes/releases/latest | jq -r '.tag_name')
KUBEVERSION=${KUBEVERSION%.*}  # Use major.minor version for repository setup
echo "Latest Kubernetes version identified as $KUBEVERSION."

# Setting up Kubernetes APT repository with the fetched version
curl -fsSL https://pkgs.k8s.io/core:/stable:/${KUBEVERSION}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBEVERSION}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
echo "Kubernetes APT repository setup completed."

# Installing Kubernetes components: kubeadm, kubelet, and kubectl
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl  # Prevent these packages from being automatically updated
echo "Kubernetes components installed and version locked."

# Disabling swap as it is a requirement for Kubernetes to function correctly
sudo swapoff -a
sudo sed -i 's/\/swap/#\/swap/' /etc/fstab
echo "Swap has been disabled to meet Kubernetes requirements."

# Setting network related system parameters required by Kubernetes
sudo tee /etc/sysctl.d/k8s.conf > /dev/null <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system  # Apply changes without needing a reboot
echo "Network settings configured for Kubernetes."

# Configuring the container runtime endpoint for Kubernetes
sudo crictl config --set runtime-endpoint=unix:///run/containerd/containerd.sock
echo "Container runtime endpoint configured for Kubernetes."

# Final instructions after setup completion
echo "Kubernetes installation is complete. Please proceed with the following steps:"
echo "1. Initialize the control node with 'sudo kubeadm init'."
echo "2. Apply the Calico network plugin by running 'kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml'."
echo "3. For worker nodes, use the command provided by 'kubeadm init' to join them to the cluster."
