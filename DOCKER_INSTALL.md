# Docker Installation Instructions

## Install Docker on Ubuntu

### Method 1: Using Official Docker Repository (Recommended)

```bash
# Update package index
sudo apt update

# Install prerequisites
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index again
sudo apt update

# Install Docker Engine
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add your user to docker group (to run without sudo)
sudo usermod -aG docker $USER

# Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Log out and log back in for group changes to take effect
# Or run: newgrp docker

# Test installation
docker --version
docker run hello-world
```

### Method 2: Using Ubuntu's Package Manager (Simpler but older version)

```bash
# Update package index
sudo apt update

# Install Docker
sudo apt install -y docker.io docker-compose

# Add user to docker group
sudo usermod -aG docker $USER

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Test installation
docker --version
```

## After Docker Installation

Once Docker is installed, you can proceed with the MQ5 Compiler setup:

```bash
cd /home/fxmathai/Desktop/2025-1/Mq5Compiler-Docker

# Build and start the service
./setup.sh build
./setup.sh run

# Test the service
./setup.sh test
```

## Alternative: Run Without Docker

If you prefer to run the service directly without Docker:

```bash
# Install Node.js if not already installed
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install dependencies
npm install

# Install Wine for MetaTrader compilation (optional for testing)
sudo apt update
sudo apt install -y wine

# Start the service
npm start

# The service will be available at http://localhost:3000
```
