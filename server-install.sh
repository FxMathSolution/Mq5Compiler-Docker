#!/bin/bash

# 🌐 MQ5 Compiler Docker Service - Ubuntu Server Auto-Install Script
# Compatible with Ubuntu 22.04 and 24.04 LTS
# Run with: curl -fsSL https://your-server/server-install.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root. Please run as a regular user with sudo access."
        exit 1
    fi
}

# Function to check Ubuntu version
check_ubuntu() {
    if ! command -v lsb_release &> /dev/null; then
        print_error "This script is designed for Ubuntu systems."
        exit 1
    fi
    
    UBUNTU_VERSION=$(lsb_release -rs)
    print_status "Detected Ubuntu $UBUNTU_VERSION"
    
    if [[ "$UBUNTU_VERSION" != "22.04" && "$UBUNTU_VERSION" != "24.04" ]]; then
        print_warning "This script is optimized for Ubuntu 22.04 or 24.04 LTS"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Function to install system updates
install_updates() {
    print_status "Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl wget git unzip software-properties-common ca-certificates gnupg lsb-release
    print_success "System packages updated"
}

# Function to install Docker
install_docker() {
    print_status "Installing Docker..."
    
    # Remove old Docker versions
    sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Add Docker's official GPG key
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
    
    print_success "Docker installed successfully"
}

# Function to install Docker Compose
install_docker_compose() {
    print_status "Installing Docker Compose..."
    
    # Docker Compose v2 is included with docker-compose-plugin
    # Also install standalone version for compatibility
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    print_success "Docker Compose installed successfully"
}

# Function to setup MQ5 Compiler project
setup_project() {
    print_status "Setting up MQ5 Compiler project..."
    
    # Create project directory
    PROJECT_DIR="/opt/mq5-compiler"
    sudo mkdir -p $PROJECT_DIR
    sudo chown $USER:$USER $PROJECT_DIR
    
    # Option 1: Clone from Git (if repository exists)
    if [[ -n "${REPO_URL:-}" ]]; then
        print_status "Cloning from repository: $REPO_URL"
        git clone $REPO_URL $PROJECT_DIR
    else
        print_status "Repository URL not provided. You'll need to upload project files manually."
        print_status "Upload your project files to: $PROJECT_DIR"
        print_status ""
        print_status "Example SCP command from your local machine:"
        print_status "scp -r /home/fxmathai/Desktop/2025-1/Mq5Compiler-Docker/* user@$(hostname -I | awk '{print $1}'):$PROJECT_DIR/"
        
        # Create basic structure for manual upload
        mkdir -p $PROJECT_DIR/{src,test-files,logs,temp,uploads,compiled}
        
        read -p "Press Enter when you have uploaded the project files..."
    fi
    
    cd $PROJECT_DIR
    
    # Make scripts executable
    if [[ -f "setup.sh" ]]; then
        chmod +x setup.sh
    fi
    if [[ -f "mock-compiler.sh" ]]; then
        chmod +x mock-compiler.sh
    fi
    if [[ -f "start.sh" ]]; then
        chmod +x start.sh
    fi
    if [[ -f "status_check.sh" ]]; then
        chmod +x status_check.sh
    fi
    
    print_success "Project setup completed in $PROJECT_DIR"
}

# Function to configure firewall
setup_firewall() {
    print_status "Configuring firewall..."
    
    # Install UFW if not present
    sudo apt install -y ufw
    
    # Reset UFW to defaults
    sudo ufw --force reset
    
    # Allow SSH (very important!)
    sudo ufw allow ssh
    sudo ufw allow 22/tcp
    
    # Allow MQ5 Compiler ports
    sudo ufw allow 3000/tcp comment "MQ5 Compiler Docker Service"
    sudo ufw allow 8000/tcp comment "FastAPI Client Interface"
    
    # Enable firewall
    sudo ufw --force enable
    
    print_success "Firewall configured and enabled"
    sudo ufw status
}

# Function to setup systemd service
setup_systemd_service() {
    print_status "Setting up auto-start systemd service..."
    
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
User=$USER
Group=docker

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd and enable service
    sudo systemctl daemon-reload
    sudo systemctl enable mq5-compiler.service
    
    print_success "Systemd service configured"
}

# Function to build and start services
build_and_start() {
    print_status "Building and starting MQ5 Compiler services..."
    
    cd /opt/mq5-compiler
    
    # Apply new group membership (for docker group)
    newgrp docker <<EOF
    # Build Docker image
    if [[ -f "setup.sh" ]]; then
        ./setup.sh build
    else
        docker-compose build
    fi
    
    # Start services
    if [[ -f "setup.sh" ]]; then
        ./setup.sh run
    else
        docker-compose up -d
    fi
EOF
    
    print_success "Services started successfully"
}

# Function to test installation
test_installation() {
    print_status "Testing installation..."
    
    # Wait for services to start
    sleep 10
    
    # Test Docker service health
    if curl -f -s http://localhost:3000/health > /dev/null; then
        print_success "Docker service (port 3000) is healthy"
    else
        print_error "Docker service health check failed"
    fi
    
    # Test FastAPI service health
    if curl -f -s http://localhost:8000/health > /dev/null; then
        print_success "FastAPI service (port 8000) is healthy"
    else
        print_warning "FastAPI service health check failed (this is optional)"
    fi
    
    # Show running containers
    print_status "Running Docker containers:"
    docker ps
}

# Function to show completion message
show_completion() {
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    echo
    print_success "🎉 MQ5 Compiler Docker Service installation completed!"
    echo
    echo "📊 Service URLs:"
    echo "   - Docker Service: http://$SERVER_IP:3000"
    echo "   - FastAPI Client: http://$SERVER_IP:8000"
    echo "   - API Documentation: http://$SERVER_IP:8000/docs"
    echo
    echo "🔍 Health Checks:"
    echo "   curl http://$SERVER_IP:3000/health"
    echo "   curl http://$SERVER_IP:8000/health"
    echo
    echo "🧪 Test Compilation:"
    echo "   curl -X POST -F \"mq5file=@your-file.mq5\" http://$SERVER_IP:3000/compile --output compiled.ex5"
    echo
    echo "📋 Management Commands:"
    echo "   cd /opt/mq5-compiler"
    echo "   ./setup.sh [run|stop|restart|logs|test]"
    echo "   sudo systemctl [start|stop|restart|status] mq5-compiler"
    echo
    echo "📁 Project Directory: /opt/mq5-compiler"
    echo "📜 Logs: docker-compose logs"
    echo
    print_warning "⚠️  You may need to log out and back in for docker group changes to take effect"
    echo
}

# Main installation function
main() {
    echo "🚀 MQ5 Compiler Docker Service - Ubuntu Server Installation"
    echo "============================================================"
    echo
    
    # Pre-flight checks
    check_root
    check_ubuntu
    
    # Installation steps
    install_updates
    install_docker
    install_docker_compose
    setup_project
    setup_firewall
    setup_systemd_service
    build_and_start
    test_installation
    show_completion
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --repo-url)
            REPO_URL="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [--repo-url <repository-url>] [--help]"
            echo
            echo "Options:"
            echo "  --repo-url    Git repository URL to clone project from"
            echo "  --help        Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run main installation
main
