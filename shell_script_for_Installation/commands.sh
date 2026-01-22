#!/bin/bash
set -e

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root."
    exit 1
fi


echo "=== Starting disk and LVM resize ==="
# ------------------------------
# Step 1: Show current disk layout
# ------------------------------
echo "Current disk layout:"
lsblk

# ------------------------------
# Step 2: Resize partition nvme0n1p4
# ------------------------------
echo "Resizing partition /dev/nvme0n1p4..."
growpart /dev/nvme0n1 4
partprobe /dev/nvme0n1

# ------------------------------
# Step 3: Extend root LV by 20G
# ------------------------------
echo "Extending root volume by 20G..."
lvextend -L +20G /dev/RootVG/rootVol

# Resize filesystem for root
echo "Growing root filesystem..."
xfs_growfs /

# ------------------------------
# Step 4: Extend /var LV by 30G
# ------------------------------
echo "Extending /var volume by 30G..."
lvextend -L +30G /dev/RootVG/varVol

# Resize filesystem for /var
echo "Growing /var filesystem..."
xfs_growfs /var

# ------------------------------
# Step 5: Verify changes
# ------------------------------
echo "=== Disk resize complete ==="
lsblk
df -h

echo "=== Done ==="

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
echo "Installing Jenkins..."
curl -fsSL --tlsv1.2 https://pkg.jenkins.io/redhat-stable/jenkins.repo -o /etc/yum.repos.d/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
dnf install -y jenkins

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

# Add Jenkins & ec2-user to Docker group
usermod -aG docker jenkins
usermod -aG docker ec2-user

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
# Verify Minikube installation
# ==============================
echo "Verifying Minikube..."
sudo -u ec2-user -i bash <<'EOF'
export PATH=$PATH:/usr/local/bin
which minikube
minikube version
EOF

# ==============================
# Start Minikube as ec2-user
# ==============================
echo "Starting Minikube..."
sudo -u ec2-user -i bash <<'EOF'
export MINIKUBE_HOME=/home/ec2-user
export PATH=$PATH:/usr/local/bin
minikube start --driver=docker
EOF

# ==============================
# Copy kubeconfig to Jenkins
# ==============================
mkdir -p /var/lib/jenkins/.kube
cp /home/ec2-user/.kube/config /var/lib/jenkins/.kube/config
chown -R jenkins:jenkins /var/lib/jenkins/.kube
chmod 600 /var/lib/jenkins/.kube/config

