#!/bin/bash
set -e

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root."
    exit 1
fi

echo "=== Running bootstrap script ==="

# ==============================
# Install basic tools
# ==============================
dnf install -y ca-certificates curl wget unzip git yum-utils dnf-plugins-core
update-ca-trust

# ==============================
# Install Java 17
# ==============================
dnf install -y java-17-openjdk

# ==============================
# Install Jenkins
# ==============================
echo "Installing Jenkins..."
curl -fsSL --tlsv1.2 https://pkg.jenkins.io/redhat-stable/jenkins.repo -o /etc/yum.repos.d/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
dnf install -y jenkins

systemctl enable jenkins
systemctl start jenkins

# ==============================
# Install Docker (real Docker, not Podman)
# ==============================
echo "Installing Docker..."
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

systemctl enable docker
systemctl start docker

# Add users to docker group
if ! getent group docker >/dev/null; then
    groupadd docker
fi
usermod -aG docker jenkins
usermod -aG docker ec2-user

# Ensure docker socket permissions
if [ -S /var/run/docker.sock ]; then
    chown root:docker /var/run/docker.sock
    chmod 660 /var/run/docker.sock
fi

# Restart services
systemctl restart docker
systemctl restart jenkins
sleep 20

# ==============================
# Install Terraform
# ==============================
echo "Installing Terraform..."
dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
dnf install -y terraform

# ==============================
# Install kubectl
# ==============================
echo "Installing kubectl..."
K8S_VERSION=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
curl -fsSL -o /usr/local/bin/kubectl https://dl.k8s.io/release/${K8S_VERSION}/bin/linux/amd64/kubectl
chmod +x /usr/local/bin/kubectl
kubectl version --client=true

# ==============================
# Install Minikube
# ==============================
echo "Installing Minikube..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install minikube-linux-amd64 /usr/local/bin/minikube
rm -f minikube-linux-amd64

# ==============================
# Ensure Jenkins SSH folder exists and generate SSH key
# ==============================
echo "Setting up Jenkins SSH keys..."
sudo -u jenkins mkdir -p /var/lib/jenkins/.ssh
sudo -u jenkins ssh-keygen -t rsa -b 4096 -f /var/lib/jenkins/.ssh/portfolio-key -N ""
chown -R jenkins:jenkins /var/lib/jenkins/.ssh
chmod 700 /var/lib/jenkins/.ssh
chmod 600 /var/lib/jenkins/.ssh/portfolio-key
chmod 644 /var/lib/jenkins/.ssh/portfolio-key.pub

# ==============================
# Start Minikube as Jenkins user
# ==============================
echo "Starting Minikube for Jenkins..."
sudo -u jenkins -i bash <<'EOF'
export MINIKUBE_HOME=/var/lib/jenkins
export PATH=$PATH:/usr/local/bin
minikube start --driver=docker
EOF

# ==============================
# Ensure Jenkins kubeconfig exists
# ==============================
mkdir -p /var/lib/jenkins/.kube
chown -R jenkins:jenkins /var/lib/jenkins/.kube
chmod 600 /var/lib/jenkins/.kube/config

echo "=== Bootstrap script completed successfully ==="
