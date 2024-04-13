#!/bin/bash

# Install Jenkins and its dependencies
echo "Installing Jenkins..."
sudo apt update
sudo apt install -y \
  ca-certificates \
  curl \
  lsb-release \
  fontconfig \
  openjdk-17-jre

wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update
sudo apt install jenkins -y

# Check if Docker is already installed
if ! command -v docker >/dev/null 2>&1; then
  echo "Installing Docker..."

  # Install Docker prerequisites
  sudo apt update
  sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

  # Add Docker repository key
  sudo mkdir -m 0755 -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

  # Add Docker repository
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt update

  # Install Docker
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin  

  echo "Docker installed successfully!"
fi

# Add user to Docker group (if script #3 is desired)
read -p "Add user to Docker group? (y/N): " add_to_docker
if [[ "$add_to_docker" =~ ^[Yy]$ ]]; then
  read -p "Enter username: " username
  sudo usermod -aG docker "$username"
  sudo service docker restart
fi

# Generate SSH key (if script #4 is desired)
read -p "Generate SSH key? (y/N): " generate_key
if [[ "$generate_key" =~ ^[Yy]$ ]]; then
  echo "Enter your username (without @gmail.com):"
  read username

  echo "Enter the name of the SSH key (without the extension):"
  read keyname

  keygen_command="sudo ssh-keygen -t ed25519 -f /root/.ssh/$keyname -C \"$username@gmail.com\""
  eval "$keygen_command"

  echo "Your public key:"
  cat /root/.ssh/$keyname.pub

  echo "Your private key (**WARNING: Do not share this**):"
  cat /root/.ssh/$keyname

  # Configure SSH for Jenkins (optional)
  read -p "Configure SSH for Jenkins? (y/N): " configure_jenkins_ssh
  if [[ "$configure_jenkins_ssh" =~ ^[Yy]$ ]]; then
    sudo mkdir -p /var/lib/jenkins/.ssh/
    sudo cp /root/.ssh/$keyname /var/lib/jenkins/.ssh/
    sudo cp /root/.ssh/$keyname.pub /var/lib/jenkins/.ssh/

    sudo chown -R jenkins:jenkins /var/lib/jenkins/.ssh/
    sudo chmod 700 /var/lib/jenkins/.ssh/
    sudo chmod 600 /var/lib/jenkins/.ssh/$keyname
    sudo chmod 644 /var/lib/jenkins/.ssh/$keyname.pub

    sudo -u jenkins ssh-keyscan -t ed25519 github.com >> /var/lib/jenkins/.ssh/known_hosts
  fi
fi

# Start and enable Jenkins service
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Display initial Jenkins password
echo "Initial Jenkins admin password:"
cat /var/lib/jenkins/secrets/initialAdminPassword

echo "Your public key:"
cat /root/.ssh/$keyname.pub

echo "Your private key (**WARNING: Do not share this**):"
cat /root/.ssh/$keyname


# Rebooting the system
read -p "Do you want to reboot the system? (y/n):" reboot_system

if [[ "$reboot_system" =~ ^[Yy]$ ]]; then
  sudo reboot
fi
