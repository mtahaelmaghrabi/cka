
# Kubernetes Cluster Setup Guide 🌐

This guide provides instructions on setting up a Kubernetes cluster using scripts from the this repository. Follow these steps to configure your cluster's master and worker nodes.

## Prerequisites 📋
- Machines (virtual or physical) for the master and worker nodes.
- Ubuntu OS and network connectivity between nodes.

## Repository Clone 📥
Clone the repository on each node:
```bash
git clone https://github.com/mtahaelmaghrabi/cka
```

## Setup for All Nodes 🛠️
Perform these steps on every node.

### Setup Container Runtime
Install containerd container runtime:
```bash
sudo cka/ubuntu/setup-container.sh
```

### Install Kubernetes Tools
Install `kubeadm`, `kubelet`, and `kubectl`:
```bash
sudo cka/ubuntu/setup-kubetools.sh
```

## Master Node Setup 👑
Perform these steps only on the master node.

### Initialize Kubernetes Cluster
Start your cluster with `kubeadm init`:
```bash
sudo kubeadm init
```

### Configure Kubectl
Setup access to the Kubernetes cluster API:
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### Install Networking Plugin
Deploy the Calico CNI plugin for networking:
```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/calico.yaml
```
For the latest release of Calico, check: [Calico Releases](https://github.com/projectcalico/calico/releases).

## Worker Nodes Setup 🛠️
Perform these steps on worker nodes only.

### Join Cluster
Join each worker to the cluster using the master's token:
```bash
kubeadm join 192.168.100.100:6443 --token 2xvr1j.v5iob57u3ktf6w5p --discovery-token-ca-cert-hash sha256:9e42aabxxxxxxxxxxxx
```

## Verification ✔️
Check that all nodes are connected:
```bash
kubectl get nodes
```

## Conclusion 🎉
Your Kubernetes cluster is ready for applications. For more info, visit the Kubernetes documentation.
