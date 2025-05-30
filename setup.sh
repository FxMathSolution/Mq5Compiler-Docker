#!/bin/bash

# MQ5 Compiler Docker Service - Build and Run Script

set -e

echo "🔧 MQ5 Compiler Docker Service Setup"
echo "======================================"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Function to show usage
show_usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  build     - Build the Docker image"
    echo "  run       - Run the service using Docker Compose"
    echo "  stop      - Stop the service"
    echo "  restart   - Restart the service"
    echo "  logs      - Show service logs"
    echo "  test      - Run a test compilation"
    echo "  clean     - Clean up containers and images"
    echo "  install   - Install client dependencies"
    echo ""
}

# Function to build the image
build_image() {
    echo "🏗️  Building Docker image..."
    docker-compose build
    echo "✅ Build completed successfully!"
}

# Function to run the service
run_service() {
    echo "🚀 Starting MQ5 Compiler Service..."
    docker-compose up -d
    echo "✅ Service started successfully!"
    echo "📊 Service URL: http://localhost:3000"
    echo "🔍 Health check: http://localhost:3000/health"
    echo ""
    echo "To view logs: $0 logs"
    echo "To stop service: $0 stop"
}

# Function to stop the service
stop_service() {
    echo "🛑 Stopping MQ5 Compiler Service..."
    docker-compose down
    echo "✅ Service stopped successfully!"
}

# Function to restart the service
restart_service() {
    echo "🔄 Restarting MQ5 Compiler Service..."
    docker-compose restart
    echo "✅ Service restarted successfully!"
}

# Function to show logs
show_logs() {
    echo "📋 Service logs:"
    docker-compose logs -f
}

# Function to test compilation
test_compilation() {
    echo "🧪 Testing compilation..."
    
    # Check if service is running
    if ! docker-compose ps | grep -q "Up"; then
        echo "❌ Service is not running. Starting service first..."
        run_service
        sleep 5
    fi
    
    # Wait for service to be ready
    echo "⏳ Waiting for service to be ready..."
    for i in {1..30}; do
        if curl -s http://localhost:3000/health > /dev/null; then
            echo "✅ Service is ready!"
            break
        fi
        if [ $i -eq 30 ]; then
            echo "❌ Service failed to start within 30 seconds"
            exit 1
        fi
        sleep 1
    done
    
    # Test with sample file
    if [ -f "test-files/SampleExpert.mq5" ]; then
        echo "📁 Testing with SampleExpert.mq5..."
        if command -v node &> /dev/null; then
            node client.js compile test-files/SampleExpert.mq5
        else
            echo "📤 Using curl for testing..."
            curl -X POST \
                -F "mq5file=@test-files/SampleExpert.mq5" \
                http://localhost:3000/compile \
                --output SampleExpert.ex5
            
            if [ -f "SampleExpert.ex5" ]; then
                echo "✅ Test compilation successful!"
                echo "📁 Output file: SampleExpert.ex5"
                ls -lh SampleExpert.ex5
            else
                echo "❌ Test compilation failed!"
            fi
        fi
    else
        echo "⚠️  Sample file not found. Testing health endpoint only..."
        curl -s http://localhost:3000/health | grep -q "OK" && echo "✅ Health check passed!" || echo "❌ Health check failed!"
    fi
}

# Function to clean up
clean_up() {
    echo "🧹 Cleaning up..."
    docker-compose down -v
    docker image prune -f
    docker system prune -f
    echo "✅ Cleanup completed!"
}

# Function to install client dependencies
install_deps() {
    echo "📦 Installing client dependencies..."
    if command -v npm &> /dev/null; then
        npm install axios form-data
        echo "✅ Dependencies installed successfully!"
        echo ""
        echo "You can now use the client:"
        echo "  node client.js health"
        echo "  node client.js compile your-file.mq5"
    else
        echo "❌ npm is not installed. Please install Node.js and npm first."
        exit 1
    fi
}

# Main script logic
case "$1" in
    build)
        build_image
        ;;
    run)
        run_service
        ;;
    stop)
        stop_service
        ;;
    restart)
        restart_service
        ;;
    logs)
        show_logs
        ;;
    test)
        test_compilation
        ;;
    clean)
        clean_up
        ;;
    install)
        install_deps
        ;;
    "")
        echo "🔧 MQ5 Compiler Docker Service"
        echo ""
        docker-compose ps 2>/dev/null || echo "Service is not running"
        echo ""
        show_usage
        ;;
    *)
        echo "❌ Unknown command: $1"
        show_usage
        exit 1
        ;;
esac
