#!/bin/bash
set -e

# ==============================
# Ensure script is running as root
# ==============================
if [ "$EUID" -ne 0 ]; then
    echo "Not running as root. Re-running with sudo..."
    exec sudo "$0" "$@"
fi

echo "=== Running commands.sh as root ==="

# ==============================
# Update system packages
# ==============================
echo "Updating system packages..."
dnf update -y

# ==============================
# Install Java 17 (required for Jenkins)
# ==============================
echo "Installing Java 17..."
dnf install -y java-17-openjdk

# ==============================
# Install Git
# ==============================
echo "Installing Git..."
dnf install -y git

# ==============================
# Install wget & curl
# ==============================
echo "Installing wget and curl..."
dnf install -y wget curl unzip

# ==============================
# Install Jenkins
# ==============================
echo "Installing Jenkins..."
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
dnf install -y jenkins

# Start and enable Jenkins
systemctl enable jenkins
systemctl start jenkins

# ==============================
# Install Docker
# ==============================
echo "Installing Docker..."
dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
systemctl enable docker
systemctl start docker

# Add Jenkins and ec2-user to Docker group
usermod -aG docker jenkins
usermod -aG docker ec2-user
systemctl restart jenkins

# ==============================
# Install Terraform
# ==============================
echo "Installing Terraform..."
dnf install -y yum-utils
dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
dnf install -y terraform
terraform -version

# ==============================
# Install kubectl
# ==============================
echo "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/
kubectl version --client

# ==============================
# Install AWS CLI v2
# ==============================
echo "Installing AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
aws --version

# ==============================
# Finish
# ==============================
echo "=== Bootstrap completed! ==="
echo "Jenkins, Docker, Terraform, kubectl, Git, Java, and AWS CLI installed."
