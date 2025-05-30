# 🌐 Ubuntu Server Deployment Guide

## 🎯 Server Requirements

### Recommended: Ubuntu 24.04 LTS
- **Why Ubuntu 24.04 LTS?**
  - Latest LTS with support until 2029
  - Better Docker performance and security
  - Enhanced package management
  - Improved kernel and drivers

### Minimum System Requirements
- **CPU**: 2+ cores
- **RAM**: 4GB+ (8GB recommended)
- **Storage**: 20GB+ free space
- **Network**: Internet connection for Docker pulls

---

## 🚀 Quick Server Deployment

### Option 1: One-Command Installation
```bash
# Download and run the complete setup
curl -fsSL https://raw.githubusercontent.com/your-repo/mq5-compiler/main/server-install.sh | bash
```

### Option 2: Manual Step-by-Step Installation

#### Step 1: Update Ubuntu System
```bash
# Update package lists
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y curl wget git unzip software-properties-common
```

#### Step 2: Install Docker (Ubuntu 24.04)
```bash
# Remove old Docker versions
sudo apt remove -y docker docker-engine docker.io containerd runc

# Add Docker's official GPG key
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER
```

#### Step 3: Install Docker Compose
```bash
# Install Docker Compose v2
sudo apt install -y docker-compose-plugin

# Or install standalone version
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

#### Step 4: Deploy MQ5 Compiler Service
```bash
# Create project directory
mkdir -p /opt/mq5-compiler
cd /opt/mq5-compiler

# Download project files (replace with your actual repository)
git clone https://github.com/your-username/mq5-compiler-docker.git .

# Or upload your local files via SCP
# scp -r /home/fxmathai/Desktop/2025-1/Mq5Compiler-Docker/* user@server:/opt/mq5-compiler/

# Make scripts executable
chmod +x setup.sh
chmod +x mock-compiler.sh
chmod +x start.sh

# Build and run the service
./setup.sh build
./setup.sh run
```

#### Step 5: Configure Firewall
```bash
# Install UFW firewall
sudo apt install -y ufw

# Allow SSH (important!)
sudo ufw allow ssh
sudo ufw allow 22/tcp

# Allow MQ5 Compiler ports
sudo ufw allow 3000/tcp comment "MQ5 Compiler Docker Service"
sudo ufw allow 8000/tcp comment "FastAPI Client Interface"

# Enable firewall
sudo ufw --force enable

# Check firewall status
sudo ufw status
```

#### Step 6: Set Up Auto-Start Services
```bash
# Create systemd service for Docker containers
sudo tee /etc/systemd/system/mq5-compiler.service > /dev/null <<EOF
[Unit]
Description=MQ5 Compiler Docker Service
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/mq5-compiler
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Enable auto-start
sudo systemctl enable mq5-compiler.service
sudo systemctl start mq5-compiler.service
```

---

## 🔍 Testing Your Deployment

### 1. Check Service Status
```bash
# Check Docker containers
docker ps

# Check service logs
docker-compose logs

# Test health endpoints
curl http://localhost:3000/health
curl http://localhost:8000/health
```

### 2. Test Compilation
```bash
# Test with sample file
curl -X POST \
  -F "mq5file=@test-files/SampleExpert.mq5" \
  http://localhost:3000/compile \
  --output ServerTest.ex5

# Check output file
ls -la ServerTest.ex5
```

### 3. Test from External Client
```bash
# Replace YOUR_SERVER_IP with your actual server IP
curl -X POST \
  -F "mq5file=@SampleExpert.mq5" \
  http://YOUR_SERVER_IP:3000/compile \
  --output RemoteTest.ex5
```

---

## 🌐 Network Configuration

### For Cloud Servers (AWS, DigitalOcean, etc.)

#### Security Groups / Firewall Rules
```
Port 22   - SSH (your IP only)
Port 3000 - MQ5 Compiler Docker Service
Port 8000 - FastAPI Client Interface
```

#### DNS Setup (Optional)
```bash
# If you have a domain, set up A records:
# mq5-compiler.yourdomain.com -> YOUR_SERVER_IP
# api.yourdomain.com -> YOUR_SERVER_IP
```

### For Local Network Deployment
```bash
# Find your server IP
ip addr show

# Test from another machine on same network
curl http://192.168.1.XXX:3000/health
```

---

## 🔒 Production Security (Recommended)

### 1. Set Up Reverse Proxy with SSL
```bash
# Install Nginx
sudo apt install -y nginx certbot python3-certbot-nginx

# Configure Nginx for MQ5 Compiler
sudo tee /etc/nginx/sites-available/mq5-compiler > /dev/null <<EOF
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /api {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable site
sudo ln -s /etc/nginx/sites-available/mq5-compiler /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# Get SSL certificate
sudo certbot --nginx -d your-domain.com
```

### 2. Set Up Authentication (Optional)
```bash
# Add API key authentication to your FastAPI client
# Update fastapi_client.py with authentication middleware
```

---

## 📊 Monitoring & Maintenance

### System Monitoring
```bash
# Check system resources
htop
df -h
docker stats

# Monitor logs
tail -f /var/log/syslog
docker-compose logs -f
```

### Maintenance Scripts
```bash
# Create maintenance script
sudo tee /opt/mq5-compiler/maintenance.sh > /dev/null <<EOF
#!/bin/bash
echo "🔧 MQ5 Compiler Maintenance - \$(date)"

# Update system
sudo apt update && sudo apt upgrade -y

# Clean Docker
docker system prune -f

# Restart services
docker-compose restart

# Check status
./status_check.sh

echo "✅ Maintenance completed"
EOF

chmod +x /opt/mq5-compiler/maintenance.sh

# Set up weekly maintenance
echo "0 2 * * 0 /opt/mq5-compiler/maintenance.sh >> /var/log/mq5-maintenance.log 2>&1" | sudo crontab -
```

---

## 🚨 Troubleshooting

### Common Issues

#### Docker Permission Denied
```bash
# Add user to docker group and restart session
sudo usermod -aG docker $USER
newgrp docker
# Or logout and login again
```

#### Port Already in Use
```bash
# Find process using port
sudo lsof -i :3000
sudo lsof -i :8000

# Kill process if needed
sudo kill -9 PID_NUMBER
```

#### Service Won't Start
```bash
# Check Docker status
sudo systemctl status docker

# Check container logs
docker-compose logs

# Rebuild if needed
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

#### Firewall Blocking Connections
```bash
# Check firewall status
sudo ufw status

# Temporarily disable for testing
sudo ufw disable

# Re-enable with proper rules
sudo ufw enable
```

---

## 📋 Deployment Checklist

- [ ] Ubuntu 24.04 LTS server prepared
- [ ] Docker and Docker Compose installed
- [ ] Project files uploaded/cloned
- [ ] Docker image built successfully
- [ ] Services running (ports 3000, 8000)
- [ ] Firewall configured
- [ ] Health checks passing
- [ ] Test compilation successful
- [ ] Auto-start services configured
- [ ] SSL/Security configured (production)
- [ ] Monitoring set up
- [ ] Backup strategy planned

---

## 📞 Quick Commands Reference

```bash
# Service Management
./setup.sh run         # Start services
./setup.sh stop        # Stop services  
./setup.sh restart     # Restart services
./setup.sh logs        # View logs
./setup.sh test        # Test compilation

# System Status
docker ps               # Running containers
docker-compose logs     # Service logs
./status_check.sh      # Full system check
systemctl status mq5-compiler  # Auto-start service

# Maintenance
docker system prune -f  # Clean unused Docker data
./maintenance.sh        # Run maintenance script
```

**🎉 Your MQ5 Compiler Service is now ready for production deployment!**
