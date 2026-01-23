#!/bin/bash
set -e

#####################################
# Root check
#####################################
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

echo "=== BOOTSTRAP STARTED ==="

#####################################
# Base tools
#####################################
dnf install -y ca-certificates curl wget unzip git yum-utils
update-ca-trust

#####################################
# Java 17 (Jenkins requirement)
#####################################
dnf install -y java-17-openjdk

#####################################
# Jenkins
#####################################
echo "Installing Jenkins..."
curl -fsSL https://pkg.jenkins.io/redhat-stable/jenkins.repo \
  -o /etc/yum.repos.d/jenkins.repo

rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

dnf install -y jenkins
systemctl enable jenkins
systemctl start jenkins

#####################################
# Docker (Amazon Linux SAFE way)
#####################################
echo "Installing Docker..."
dnf install -y docker

systemctl enable docker
systemctl start docker

#####################################
# Docker permissions
#####################################
echo "Configuring Docker permissions..."

# Ensure docker group exists
getent group docker || groupadd docker

# Add users
usermod -aG docker jenkins
usermod -aG docker ec2-user

# Restart services so group takes effect
systemctl restart docker
systemctl restart jenkins

sleep 20

#####################################
# Terraform
#####################################
echo "Installing Terraform..."
dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
dnf install -y terraform

#####################################
# kubectl
#####################################
echo "Installing kubectl..."
K8S_VERSION=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
curl -fsSL -o /usr/local/bin/kubectl \
  https://dl.k8s.io/release/${K8S_VERSION}/bin/linux/amd64/kubectl
chmod +x /usr/local/bin/kubectl

#####################################
# Minikube
#####################################
echo "Installing Minikube..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install minikube-linux-amd64 /usr/local/bin/minikube
rm -f minikube-linux-amd64

#####################################
# Start Minikube as ec2-user
#####################################
echo "Starting Minikube as ec2-user..."
sudo -u ec2-user -i bash <<'EOF'
export PATH=/usr/local/bin:$PATH
export MINIKUBE_HOME=/home/ec2-user

minikube delete || true
minikube start --driver=docker --memory=3072 --cpus=2
EOF

#####################################
# Share kubeconfig with Jenkins
#####################################
echo "Configuring kubeconfig for Jenkins..."
mkdir -p /var/lib/jenkins/.kube
cp /home/ec2-user/.kube/config /var/lib/jenkins/.kube/config
chown -R jenkins:jenkins /var/lib/jenkins/.kube
chmod 600 /var/lib/jenkins/.kube/config

#####################################
# Validation
#####################################
echo "Validating setup..."

sudo -u jenkins docker ps >/dev/null 2>&1 || {
  echo "ERROR: Jenkins cannot access Docker"
  exit 1
}

sudo -u jenkins kubectl get nodes >/dev/null 2>&1 || {
  echo "WARNING: kubectl access not ready yet (Minikube may still be starting)"
}

echo "=== BOOTSTRAP COMPLETE ==="
echo "Jenkins URL: http://<EC2_PUBLIC_IP>:8080"



# #!/bin/bash
# set -e

# # Ensure script is run as root
# if [ "$EUID" -ne 0 ]; then
#     echo "Please run as root."
#     exit 1
# fi

# echo "=== Running bootstrap script ==="

# # ==============================
# # Install basic tools
# # ==============================
# dnf install -y ca-certificates curl wget unzip git yum-utils
# update-ca-trust

# # ==============================
# # Install Java 17
# # ==============================
# dnf install -y java-17-openjdk

# # ==============================
# # Install Jenkins
# # ==============================
# echo "Installing Jenkins..."
# curl -fsSL --tlsv1.2 https://pkg.jenkins.io/redhat-stable/jenkins.repo -o /etc/yum.repos.d/jenkins.repo
# rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
# dnf install -y jenkins

# systemctl enable jenkins
# systemctl start jenkins

# # ==============================
# # Configure Docker permissions (AUTOMATED)
# # ==============================
# echo "Configuring Docker permissions..."

# # Create docker group if it does not exist
# if ! getent group docker >/dev/null; then
#     groupadd docker
# fi

# # Add users to docker group
# usermod -aG docker jenkins
# usermod -aG docker ec2-user

# # Ensure docker socket permissions
# if [ -S /var/run/docker.sock ]; then
#     chown root:docker /var/run/docker.sock
#     chmod 660 /var/run/docker.sock
# fi

# # Restart services so permissions take effect
# systemctl restart docker
# systemctl restart jenkins

# # Wait for Jenkins to come up cleanly
# sleep 20

# # ==============================
# # Install Terraform for instance creation
# # ==============================
# echo "Installing Terraform..."
# dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
# dnf install -y terraform

# # ==============================
# # Install kubectl
# # ==============================
# echo "Installing kubectl..."
# K8S_VERSION=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
# curl -fsSL -o /usr/local/bin/kubectl https://dl.k8s.io/release/${K8S_VERSION}/bin/linux/amd64/kubectl
# chmod +x /usr/local/bin/kubectl
# kubectl version --client=true

# # ==============================
# # Install Minikube
# # ==============================
# echo "Installing Minikube..."
# curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
# install minikube-linux-amd64 /usr/local/bin/minikube
# rm -f minikube-linux-amd64

# # ==============================
# # Verify Minikube installation
# # ==============================
# # echo "Verifying Minikube..."
# # sudo -u ec2-user -i bash <<'EOF'
# # export PATH=$PATH:/usr/local/bin
# # which minikube
# # minikube version
# # EOF

# sudo -u jenkins -i bash <<'EOF'
# export PATH=/usr/local/bin:$PATH
# export MINIKUBE_HOME=/var/lib/jenkins
# minikube start --driver=docker
# EOF



# # ==============================
# # Start Minikube as Jenkins user
# # ==============================
# echo "Starting Minikube for Jenkins..."
# sudo -u jenkins -i bash <<'EOF'
# export MINIKUBE_HOME=/var/lib/jenkins
# export PATH=$PATH:/usr/local/bin
# minikube start --driver=docker
# EOF


# # # ==============================
# # # Copy kubeconfig to Jenkins
# # # ==============================
# # mkdir -p /var/lib/jenkins/.kube
# # cp /home/ec2-user/.kube/config /var/lib/jenkins/.kube/config
# # chown -R jenkins:jenkins /var/lib/jenkins/.kube
# # chmod 600 /var/lib/jenkins/.kube/config

# # # ==============================

# # ==============================
# # Ensure Jenkins kubeconfig exists
# # ==============================
# mkdir -p /var/lib/jenkins/.kube
# chown -R jenkins:jenkins /var/lib/jenkins/.kube
# chmod 600 /var/lib/jenkins/.kube/config


