#!/bin/bash
set -e

# ==============================
# Ensure script is running as root
# ==============================
if [ "$EUID" -ne 0 ]; then
    exec sudo "$0" "$@"
fi

echo "=== Running bootstrap script ==="

# ==============================
# Install basic tools
# ==============================
dnf install -y ca-certificates curl wget unzip git yum-utils
update-ca-trust

# ==============================
# Install Java 17
# ==============================
dnf install -y java-17-openjdk

# ==============================
# Install Jenkins
# ==============================
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
dnf install -y jenkins
systemctl enable jenkins
systemctl start jenkins

# ==============================
# Install Docker
# ==============================
dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
dnf install -y docker-ce docker-ce-cli containerd.io
systemctl enable docker
systemctl start docker

usermod -aG docker jenkins
usermod -aG docker ec2-user

# ==============================
# Install Terraform
# ==============================
dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
dnf install -y terraform

# ==============================
# Install kubectl
# ==============================
K8S_VERSION=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
curl -fsSL -o /usr/local/bin/kubectl \
  https://dl.k8s.io/release/${K8S_VERSION}/bin/linux/amd64/kubectl
chmod +x /usr/local/bin/kubectl

# ==============================
# Install Minikube
# ==============================
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install minikube-linux-amd64 /usr/local/bin/minikube
rm -f minikube-linux-amd64

# ==============================
# Start Minikube as ec2-user
# ==============================
sudo -u ec2-user minikube start --driver=docker

# ==============================
# Copy kubeconfig to Jenkins
# ==============================
mkdir -p /var/lib/jenkins/.kube
cp /home/ec2-user/.kube/config /var/lib/jenkins/.kube/config
chown -R jenkins:jenkins /var/lib/jenkins/.kube
chmod 600 /var/lib/jenkins/.kube/config

# ==============================
# Restart Jenkins
# ==============================
systemctl restart jenkins

echo "=== SETUP COMPLETE ==="
echo "Jenkins: http://<EC2_PUBLIC_IP>:8080"
echo "Verify with:"
echo "sudo -u jenkins kubectl get nodes"
