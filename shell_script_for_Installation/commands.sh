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
# Install essential tools & CA certificates first
# ==============================
echo "Installing CA certificates, curl, wget, openssl, unzip..."
dnf install -y ca-certificates curl wget openssl unzip
update-ca-trust

# Force curl & wget to use TLS1.2 by default
export CURL_CA_BUNDLE=/etc/ssl/certs/ca-bundle.crt
export GIT_SSL_CAINFO=/etc/ssl/certs/ca-bundle.crt

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
# Install Jenkins
# ==============================
echo "Installing Jenkins..."
wget --secure-protocol=TLSv1_2 -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
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
curl --tlsv1.2 -LO "https://dl.k8s.io/release/$(curl -L -s --tlsv1.2 https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/
kubectl version --client

# ==============================
# Install AWS CLI v2
# ==============================
echo "Installing AWS CLI v2..."
curl --tlsv1.2 "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
aws --version

# ==============================
# Finish
# ==============================
echo "=== Bootstrap completed! ==="
echo "Installed: Jenkins, Docker, Terraform, kubectl, Git, Java, AWS CLI"
echo "Jenkins URL: http://<EC2_PUBLIC_IP>:8080"
echo "Initial admin password: sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
