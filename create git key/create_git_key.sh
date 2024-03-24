#!/bin/bash

# Request username
echo "Enter your username (without @gmail.com):"
read username

# Request key name
echo "Enter the name of the SSH key (without the extension):"
read keyname

# Creating the ssh-keygen command
keygen_command="sudo ssh-keygen -t ed25519 -f /root/.ssh/$keyname -C \"$username@gmail.com\""

# Execution of the ssh-keygen command
eval $keygen_command

# Output of public and private keys
echo "Your public key:"
cat /root/.ssh/$keyname.pub

echo "Your private key:"
cat /root/.ssh/$keyname

# Create .ssh folder for Jenkins
sudo mkdir -p /var/lib/jenkins/.ssh/

# Copy keys for Jenkins
sudo cp /root/.ssh/$keyname /var/lib/jenkins/.ssh/
sudo cp /root/.ssh/$keyname.pub /var/lib/jenkins/.ssh/

# Change the owner of the .ssh folder
sudo chown -R jenkins:jenkins /var/lib/jenkins/.ssh/

# Setting access rights
sudo chmod 700 /var/lib/jenkins/.ssh/
sudo chmod 600 /var/lib/jenkins/.ssh/$keyname
sudo chmod 644 /var/lib/jenkins/.ssh/$keyname.pub

# Update known_hosts for Jenkins
sudo -u jenkins ssh-keyscan -t ed25519 github.com >> /var/lib/jenkins/.ssh/known_hosts

# Restart Jenkins
sudo systemctl restart jenkins

# Repeated output of keys
echo "Your public key:"
cat /root/.ssh/$keyname.pub

echo "Your private key:"
cat /root/.ssh/$keyname
