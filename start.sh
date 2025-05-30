#!/bin/bash

echo "🚀 Starting MQ5 Compiler Service..."

# Start Xvfb for GUI applications (needed for Wine)
echo "🖥️  Starting virtual display..."
Xvfb :99 -screen 0 1024x768x16 &
export DISPLAY=:99

# Wait a moment for Xvfb to start
sleep 2

# Initialize Wine environment if needed
if [ ! -d "/root/.wine" ]; then
    echo "🍷 Initializing Wine environment..."
    winecfg &
    sleep 5
    pkill -f winecfg
fi

echo "🔧 Starting Node.js application..."
# Start the Node.js application
exec node src/server.js
