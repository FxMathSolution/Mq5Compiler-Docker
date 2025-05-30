#!/bin/bash

# Simple MetaTrader 5 Installation Script
echo "🚀 Installing MetaTrader 5 Compiler Environment"
echo "==============================================="

# Update system
sudo apt-get update

# Install Wine dependencies
echo "📦 Installing Wine and dependencies..."
sudo apt-get install -y software-properties-common
sudo dpkg --add-architecture i386
sudo mkdir -pm755 /etc/apt/keyrings
sudo wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/jammy/winehq-jammy.sources
sudo apt-get update
sudo apt-get install -y winehq-stable

# Install additional dependencies
sudo apt-get install -y wget curl xvfb winetricks

# Configure Wine prefix
export WINEPREFIX=/opt/mq5-compiler/.wine
export DISPLAY=:99
sudo mkdir -p $WINEPREFIX
sudo chown -R fxmath:fxmath $WINEPREFIX

# Start virtual display
Xvfb :99 -screen 0 1024x768x16 &

# Initialize Wine
WINEDLLOVERRIDES="mscoree,mshtml=" wine wineboot --init

# Install required Windows components
winetricks -q vcrun2019 corefonts

# Download MetaTrader 5
echo "📥 Downloading MetaTrader 5..."
cd /tmp
wget -O mt5setup.exe "https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe"

# Install MetaTrader 5 silently
echo "🔧 Installing MetaTrader 5..."
wine /tmp/mt5setup.exe /S

echo "✅ MetaTrader 5 installation completed!"
echo "📂 Installation path: $WINEPREFIX/drive_c/Program Files/MetaTrader 5/"

# List installation contents
ls -la "$WINEPREFIX/drive_c/Program Files/MetaTrader 5/" 2>/dev/null || echo "Installation directory not found"
