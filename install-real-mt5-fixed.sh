#!/bin/bash

# Real MetaTrader 5 Compiler Installation Script
# Fixed version that handles repository issues

set -e

LOG_FILE="/opt/mq5-compiler/mt5-install-fixed.log"
WINE_PREFIX="/opt/mq5-compiler/.wine"
MT5_DIR="$WINE_PREFIX/drive_c/Program Files/MetaTrader 5"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "=== MetaTrader 5 Real Compiler Installation Started ==="

# Function to check if running as root or with sudo
check_privileges() {
    if [ "$EUID" -ne 0 ]; then
        log "This script requires root privileges. Please run with sudo."
        exit 1
    fi
}

# Function to fix repository issues
fix_repositories() {
    log "Fixing Ubuntu repository configuration..."
    
    # Backup original sources
    cp /etc/apt/sources.list /etc/apt/sources.list.backup || true
    
    # Create a new sources.list with working mirrors
    cat > /etc/apt/sources.list << 'EOF'
# Ubuntu Main Repositories
deb http://archive.ubuntu.com/ubuntu/ jammy main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-backports main restricted universe multiverse

# Alternative mirrors (fallback)
deb http://us.archive.ubuntu.com/ubuntu/ jammy main restricted universe multiverse
deb http://us.archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe multiverse
EOF

    # Clean apt cache and update
    apt clean
    apt update --fix-missing || {
        log "Primary repositories failed, trying alternative approach..."
        
        # Try different mirror
        cat > /etc/apt/sources.list << 'EOF'
deb http://mirror.ubuntu.com/ubuntu/ jammy main restricted universe multiverse
deb http://mirror.ubuntu.com/ubuntu/ jammy-updates main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse
EOF
        apt clean
        apt update || log "Repository update failed, continuing with cached packages..."
    }
}

# Function to install Wine from cached packages or alternative sources
install_wine() {
    log "Installing Wine and dependencies..."
    
    # Try to install from cache first
    if apt install -y wine wine32 wine64 winetricks xvfb 2>/dev/null; then
        log "Wine installed successfully from repositories"
        return 0
    fi
    
    log "Repository installation failed, trying Snap package..."
    if command -v snap >/dev/null 2>&1; then
        snap install wine-platform-runtime || true
        snap install wine-platform-6-stable || true
    fi
    
    # If still no Wine, try downloading directly
    if ! command -v wine >/dev/null 2>&1; then
        log "Installing Wine from WineHQ..."
        
        # Add WineHQ repository
        wget -qO- https://dl.winehq.org/wine-builds/winehq.key | apt-key add - || true
        echo "deb https://dl.winehq.org/wine-builds/ubuntu/ jammy main" > /etc/apt/sources.list.d/winehq.list
        
        apt update || true
        apt install -y --install-recommends winehq-stable || {
            log "WineHQ installation failed, using static Wine build..."
            install_static_wine
        }
    fi
}

# Function to install static Wine build
install_static_wine() {
    log "Installing static Wine build..."
    
    cd /tmp
    
    # Download Wine AppImage or static build
    wget -O wine.tar.xz https://github.com/Kron4ek/Wine-Builds/releases/download/8.21/wine-8.21-amd64.tar.xz || {
        log "Failed to download Wine build"
        return 1
    }
    
    # Extract to /opt
    mkdir -p /opt/wine
    tar -xf wine.tar.xz -C /opt/wine --strip-components=1
    
    # Create symlinks
    ln -sf /opt/wine/bin/wine /usr/local/bin/wine
    ln -sf /opt/wine/bin/winecfg /usr/local/bin/winecfg
    ln -sf /opt/wine/bin/wineserver /usr/local/bin/wineserver
    
    log "Static Wine build installed"
}

# Function to setup Wine environment
setup_wine() {
    log "Setting up Wine environment..."
    
    # Set Wine prefix
    export WINEPREFIX="$WINE_PREFIX"
    export WINEDEBUG=-all
    export DISPLAY=:99
    
    # Start virtual display
    Xvfb :99 -screen 0 1024x768x16 &
    XVFB_PID=$!
    sleep 2
    
    # Initialize Wine prefix as user fxmath
    sudo -u fxmath WINEPREFIX="$WINE_PREFIX" WINEDEBUG=-all wine wineboot --init
    
    # Install necessary Wine components
    sudo -u fxmath WINEPREFIX="$WINE_PREFIX" WINEDEBUG=-all winetricks -q corefonts vcrun2019 || {
        log "Winetricks installation failed, continuing without optional components"
    }
    
    # Kill virtual display
    kill $XVFB_PID 2>/dev/null || true
}

# Function to download and install MetaTrader 5
install_mt5() {
    log "Downloading MetaTrader 5..."
    
    cd /tmp
    
    # Download MT5 installer
    wget -O mt5setup.exe "https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe" || {
        log "Failed to download MT5 installer"
        return 1
    }
    
    log "Installing MetaTrader 5..."
    
    export WINEPREFIX="$WINE_PREFIX"
    export WINEDEBUG=-all
    export DISPLAY=:99
    
    # Start virtual display
    Xvfb :99 -screen 0 1024x768x16 &
    XVFB_PID=$!
    sleep 2
    
    # Install MT5 silently
    sudo -u fxmath WINEPREFIX="$WINE_PREFIX" WINEDEBUG=-all wine mt5setup.exe /S || {
        log "Silent installation failed, trying interactive mode..."
        sudo -u fxmath WINEPREFIX="$WINE_PREFIX" WINEDEBUG=-all wine mt5setup.exe
    }
    
    # Kill virtual display
    kill $XVFB_PID 2>/dev/null || true
    
    log "MetaTrader 5 installation completed"
}

# Function to create real compiler script
create_real_compiler() {
    log "Creating real MT5 compiler script..."
    
    cat > /opt/mq5-compiler/real-compiler.sh << 'EOF'
#!/bin/bash

# Real MetaTrader 5 Compiler Script

set -e

INPUT_FILE="$1"
OUTPUT_FILE="$2"

if [ -z "$INPUT_FILE" ] || [ -z "$OUTPUT_FILE" ]; then
    echo "Usage: $0 <input.mq5> <output.ex5>"
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found"
    exit 1
fi

# Wine configuration
export WINEPREFIX="/opt/mq5-compiler/.wine"
export WINEDEBUG=-all
export DISPLAY=:99

# Start virtual display if not running
if ! pgrep -f "Xvfb :99" > /dev/null; then
    Xvfb :99 -screen 0 1024x768x16 &
    sleep 2
fi

# MetaTrader 5 paths
MT5_DIR="$WINEPREFIX/drive_c/Program Files/MetaTrader 5"
COMPILER="$MT5_DIR/metaeditor64.exe"

if [ ! -f "$COMPILER" ]; then
    echo "Error: MetaTrader 5 compiler not found at $COMPILER"
    exit 1
fi

# Copy input file to Wine directory
WINE_INPUT="/tmp/$(basename "$INPUT_FILE")"
cp "$INPUT_FILE" "$WINE_INPUT"

# Compile using MetaEditor
echo "Compiling $INPUT_FILE using real MT5 compiler..."

wine "$COMPILER" /compile:"$WINE_INPUT" /log || {
    echo "Compilation failed"
    exit 1
}

# Find and copy output file
WINE_OUTPUT="${WINE_INPUT%.mq*}.ex5"

if [ -f "$WINE_OUTPUT" ]; then
    cp "$WINE_OUTPUT" "$OUTPUT_FILE"
    echo "Compilation successful: $OUTPUT_FILE"
    
    # Cleanup
    rm -f "$WINE_INPUT" "$WINE_OUTPUT"
else
    echo "Error: Compiled file not found"
    exit 1
fi
EOF

    chmod +x /opt/mq5-compiler/real-compiler.sh
    chown fxmath:fxmath /opt/mq5-compiler/real-compiler.sh
}

# Function to update Docker service
update_docker_service() {
    log "Updating Docker service to use real compiler..."
    
    # Backup current compiler
    cp /opt/mq5-compiler/enhanced-compiler.sh /opt/mq5-compiler/enhanced-compiler.sh.backup
    
    # Replace with real compiler
    cp /opt/mq5-compiler/real-compiler.sh /opt/mq5-compiler/enhanced-compiler.sh
    
    # Restart Docker service
    cd /opt/mq5-compiler
    docker-compose restart
    
    log "Docker service updated and restarted"
}

# Main installation process
main() {
    log "Starting MetaTrader 5 real compiler installation..."
    
    check_privileges
    
    log "Step 1: Fixing repository configuration..."
    fix_repositories
    
    log "Step 2: Installing Wine..."
    install_wine
    
    log "Step 3: Setting up Wine environment..."
    setup_wine
    
    log "Step 4: Installing MetaTrader 5..."
    install_mt5
    
    log "Step 5: Creating real compiler script..."
    create_real_compiler
    
    log "Step 6: Updating Docker service..."
    update_docker_service
    
    log "=== Installation completed successfully! ==="
    log "Real MetaTrader 5 compiler is now active"
    log "Test the service: curl -X POST -F 'mq5file=@test.mq5' http://localhost:3000/compile -o test.ex5"
}

# Run main function
main "$@"
