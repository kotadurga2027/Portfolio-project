#!/bin/bash
set -e

# ==============================
# Ensure script is running as root
# ==============================
if [ "$EUID" -ne 0 ]; then
    exec sudo "$0" "$@"
fi

echo "=== Running commands.sh as root ==="

# ==============================
# Base packages
# ==============================
dnf install -y \
  ca-certificates \
  curl \
  wget \
  openssl \
  unzip \
  git \
  dnf-plugins-core \
  yum-utils

update-ca-trust

# ==============================
# Update system
# ==============================
dnf update -y

# ==============================
# Java 17
# ==============================
dnf install -y java-17-openjdk

# ==============================
# Jenkins
# ==============================
wget --secure-protocol=TLSv1_2 \
  -O /etc/yum.repos.d/jenkins.repo \
  https://pkg.jenkins.io/redhat-stable/jenkins.repo

rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
dnf install -y jenkins

systemctl enable jenkins
systemctl start jenkins

# ==============================
# Docker
# ==============================
dnf config-manager --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo

dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

systemctl enable docker
systemctl start docker

usermod -aG docker jenkins
usermod -aG docker ec2-user

systemctl restart jenkins

# ==============================
# Terraform
# ==============================
dnf config-manager --add-repo \
  https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo

dnf install -y terraform

# ==============================
# kubectl
# ==============================
K8S_VERSION=$(curl -fsSL https://dl.k8s.io/release/stable.txt)

curl -fsSL \
  -o /usr/local/bin/kubectl \
  "https://dl.k8s.io/release/${K8S_VERSION}/bin/linux/amd64/kubectl"

chmod +x /usr/local/bin/kubectl
kubectl version --client || true

# ==============================
# AWS CLI v2
# ==============================
curl -fsSL \
  "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
  -o /tmp/awscliv2.zip

unzip -o /tmp/awscliv2.zip -d /tmp
/tmp/aws/install --update

# ==============================
# 🔥 IMPORTANT: Configure kubectl for Jenkins (EKS)
# ==============================
mkdir -p /var/lib/jenkins/.kube
chown -R jenkins:jenkins /var/lib/jenkins/.kube

sudo -u jenkins aws eks update-kubeconfig \
  --region us-east-1 \
  --name <YOUR_EKS_CLUSTER_NAME>

sudo -u jenkins kubectl get nodes

# ==============================
# Finish
# ==============================
echo "=== Bootstrap completed successfully ==="
echo "Jenkins URL: http://<EC2_PUBLIC_IP>:8080"
echo "Initial admin password:"
cat /var/lib/jenkins/secrets/initialAdminPassword
