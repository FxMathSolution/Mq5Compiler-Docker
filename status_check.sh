#!/bin/bash

# MQ5 Compiler Docker Service - Status Check Script
# ================================================

echo "🔍 MQ5 Compiler Docker Service Status Check"
echo "=============================================="
echo

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check service
check_service() {
    local url=$1
    local name=$2
    
    echo -n "📡 Checking $name... "
    
    if curl -s "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ ONLINE${NC}"
        return 0
    else
        echo -e "${RED}❌ OFFLINE${NC}"
        return 1
    fi
}

# Check Docker service
echo "🐳 DOCKER SERVICE CHECK"
echo "----------------------"
check_service "http://localhost:3000/health" "Docker Service (Port 3000)"

# Check if Docker container is running
echo -n "🔧 Docker Container Status... "
if sudo docker ps | grep -q "mq5-compiler"; then
    echo -e "${GREEN}✅ RUNNING${NC}"
else
    echo -e "${RED}❌ NOT RUNNING${NC}"
    echo "   To start: sudo docker start mq5-compiler"
fi

echo

# Check FastAPI service
echo "🌐 FASTAPI CLIENT CHECK"
echo "----------------------"
check_service "http://localhost:8000/health" "FastAPI Client (Port 8000)"

# Check if FastAPI process is running
echo -n "🔧 FastAPI Process Status... "
if pgrep -f "fastapi_client.py" > /dev/null; then
    echo -e "${GREEN}✅ RUNNING${NC}"
else
    echo -e "${RED}❌ NOT RUNNING${NC}"
    echo "   To start: source env/bin/activate && python fastapi_client.py"
fi

echo

# Test compilation
echo "🔨 COMPILATION TEST"
echo "------------------"
if [ -f "test-files/SampleExpert.mq5" ]; then
    echo -n "📝 Testing Docker compilation... "
    if curl -s -X POST -F "mq5file=@test-files/SampleExpert.mq5" http://localhost:3000/compile --output /tmp/test-docker.ex5 2>/dev/null; then
        if [ -f "/tmp/test-docker.ex5" ] && [ -s "/tmp/test-docker.ex5" ]; then
            echo -e "${GREEN}✅ SUCCESS${NC} ($(stat -c%s /tmp/test-docker.ex5) bytes)"
            rm -f /tmp/test-docker.ex5
        else
            echo -e "${RED}❌ FAILED (No output file)${NC}"
        fi
    else
        echo -e "${RED}❌ FAILED (Request failed)${NC}"
    fi
    
    echo -n "📝 Testing FastAPI compilation... "
    if curl -s -X POST -F "file=@test-files/SampleExpert.mq5" http://localhost:8000/compile --output /tmp/test-fastapi.ex5 2>/dev/null; then
        if [ -f "/tmp/test-fastapi.ex5" ] && [ -s "/tmp/test-fastapi.ex5" ]; then
            echo -e "${GREEN}✅ SUCCESS${NC} ($(stat -c%s /tmp/test-fastapi.ex5) bytes)"
            rm -f /tmp/test-fastapi.ex5
        else
            echo -e "${RED}❌ FAILED (No output file)${NC}"
        fi
    else
        echo -e "${RED}❌ FAILED (Request failed)${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  No test file found (test-files/SampleExpert.mq5)${NC}"
fi

echo

# Network information
echo "🌐 NETWORK INFORMATION"
echo "---------------------"
echo "🏠 Local Access URLs:"
echo "   • Docker Service:     http://localhost:3000"
echo "   • FastAPI Client:     http://localhost:8000"
echo "   • API Documentation:  http://localhost:8000/docs"

echo
echo "🌍 External Access (replace with your server IP):"
LOCAL_IP=$(ip route get 1.1.1.1 | awk '{print $7}' | head -1)
if [ ! -z "$LOCAL_IP" ]; then
    echo "   • Docker Service:     http://$LOCAL_IP:3000"
    echo "   • FastAPI Client:     http://$LOCAL_IP:8000"
    echo "   • API Documentation:  http://$LOCAL_IP:8000/docs"
else
    echo "   • Docker Service:     http://YOUR_SERVER_IP:3000"
    echo "   • FastAPI Client:     http://YOUR_SERVER_IP:8000"
    echo "   • API Documentation:  http://YOUR_SERVER_IP:8000/docs"
fi

echo

# Quick commands
echo "⚡ QUICK COMMANDS"
echo "----------------"
echo "🔧 Docker Management:"
echo "   sudo docker ps                          # Check container status"
echo "   sudo docker logs mq5-compiler           # View Docker logs"
echo "   sudo docker restart mq5-compiler        # Restart Docker service"
echo
echo "🌐 FastAPI Management:"
echo "   pgrep -f fastapi_client.py               # Check FastAPI process"
echo "   pkill -f fastapi_client.py               # Stop FastAPI client"
echo "   source env/bin/activate && python fastapi_client.py  # Start FastAPI client"
echo
echo "🧪 Test Compilation:"
echo "   curl -X POST -F \"mq5file=@test-files/SampleExpert.mq5\" http://localhost:3000/compile -o test.ex5"
echo "   curl -X POST -F \"file=@test-files/SampleExpert.mq5\" http://localhost:8000/compile -o test.ex5"

echo
echo "✅ Status check complete!"
echo "📖 For detailed documentation, see: DEPLOYMENT_GUIDE.md"
