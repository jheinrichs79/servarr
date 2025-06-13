#!/bin/bash
echo "==================================================="
echo " Welcome to the homeServarr Setup Script"
echo " Written by: Jared Heinrichs"
echo " https://github.com/jheinrichs79/homeServarr"
echo "==================================================="


# Make default folders in homeservarr home directory
#     /home/homeservarr
#========================================================
cd ~
#mkdir media <-- This folder should already be made if you are following along on my substack "https://jaredheinrichs.substack.com/publish/post/161605988"
mkdir git
mkdir media
mkdir downloads
mkdir shared


#Ensures the server is setup for pi-hole docker install
#========================================================
CONFIG_FILE="/etc/systemd/resolved.conf"
# Ensure the line is uncommented and changed
sudo sed -i 's/#DNSStubListener=yes/DNSStubListener=no/' "$CONFIG_FILE"

# Restart systemd-resolved to apply the changes
sudo systemctl restart systemd-resolved
sudo service systemd-resolved restart
echo "Updated DNSStubListener setting and restarted systemd-resolved."


#Install smart monitoring for Hard drives
#========================================================
sudo apt install smartmontools


# Install git if not already installed
#========================================================
if ! command -v git &> /dev/null; then
    echo "Git not found. Installing git..."
    sudo apt-get update
    sudo apt-get install -y git
fi

# Configure git globally if not already configured
if [ -z "$(git config --global user.name)" ]; then
    echo "Enter your Git username:"
    read git_username
    git config --global user.name "$git_username"
fi

if [ -z "$(git config --global user.email)" ]; then
    echo "Enter your Git email:"
    read git_email
    git config --global user.email "$git_email"
fi


# Clone the repository
#========================================================
cd ~
cd git
echo "Cloning repository..."
git clone https://github.com/jheinrichs79/homeServarr.git

read -n 1 -s -p "Press any key to continue..."

if [ $? -eq 0 ]; then
    echo "Repository cloned successfully!"
else
    echo "Failed to clone repository. Please check your internet connection and repository URL."
fi

# Make all files and folders executable in the specified directory
#========================================================
cd ~/git/homeServarr/serverScripts
sudo chmod -R +x .


# Install Docker dependencies
#========================================================
sudo apt-get install -y ca-certificates curl gnupg

# Add Docker's official GPG key
echo "Add Docker's official GPG key"
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo ""
echo ""

# Add Docker repository
echo "Add Docker Repository"
echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
echo ""
echo ""


# Install Docker
#========================================================
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add current user to docker group
sudo usermod -aG docker $USER

#pause
read -n 1 -s -p "Press any key to continue..."

# Verify installation
docker --version


# Install webmin
#========================================================
echo "Installing webmin..."
sudo curl -o setup-repos.sh https://raw.githubusercontent.com/webmin/webmin/master/setup-repos.sh; sudo bash setup-repos.sh
sudo apt install -y webmin


# Get IP address and display access info
IP=$(hostname -I | cut -d' ' -f1)
echo "Webmin installed successfully!"
echo ""
echo ""


# Install Samba and dependencies
#========================================================
echo "Installing Samba..."
sudo apt-get install -y samba samba-common-bin

#Setup SAMBA USER
echo "Creating SAMBA user: 'homeservarr'"

#Add the Samba User
sudo smbpasswd -a homeservarr

#Enable the User in Samba
sudo smbpasswd -e homeservarr
echo ""
echo "Verifying SAMBA Users created"
sudo pdbedit -L | grep homeservarr
echo ""
echo ""
echo "Restarting SAMBA Service"
sudo systemctl restart smbd nmbd
read -n 1 -s -p "Press any key to continue..."
echo ""
echo ""

# Create Samba config backup
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.bak
sudo cp /home/homeservarr/git/homeServarr/configFiles/full.smb.conf /etc/samba/smb.conf

# Restart Samba service
sudo systemctl restart smbd
sudo systemctl restart nmbd

#Edit SMB.CONF file
sudo nano /etc/samba/smb.conf

echo ""
echo ""
echo "Samba installation complete!"
echo "Default public share created at /samba/public"
echo ""
echo ""

# Disable Firewall
sudo ufw disable
sudo systemctl stop firewalld

echo ""
echo "Access Webmin at https://$IP:10000"
echo "Access Network Shares at smb://$IP"
