#!/bin/bash

# MQ5 Compiler Service - Bash Client Example

BASE_URL="http://localhost:3000"

# Function to show usage
show_usage() {
    echo "🔧 MQ5 Compiler Bash Client"
    echo ""
    echo "Usage:"
    echo "  $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  health                - Check service health"
    echo "  compile <file>        - Compile a single MQ5 file"
    echo "  compile <file> <out>  - Compile with custom output name"
    echo ""
    echo "Examples:"
    echo "  $0 health"
    echo "  $0 compile my-expert.mq5"
    echo "  $0 compile my-expert.mq5 compiled.ex5"
    echo ""
}

# Function to check service health
check_health() {
    echo "🔍 Checking service health..."
    
    response=$(curl -s -w "\n%{http_code}" "$BASE_URL/health")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "200" ]; then
        echo "✅ Service is healthy"
        echo "$body" | jq . 2>/dev/null || echo "$body"
        return 0
    else
        echo "❌ Service health check failed (HTTP $http_code)"
        echo "$body"
        return 1
    fi
}

# Function to compile MQ5 file
compile_file() {
    local input_file="$1"
    local output_file="$2"
    
    if [ ! -f "$input_file" ]; then
        echo "❌ File not found: $input_file"
        return 1
    fi
    
    if [ -z "$output_file" ]; then
        output_file="${input_file%.mq*}.ex5"
    fi
    
    echo "📤 Uploading and compiling: $input_file"
    echo "📁 Output file: $output_file"
    
    # Use curl to upload and download
    response=$(curl -s -w "\n%{http_code}" \
        -X POST \
        -F "mq5file=@$input_file" \
        "$BASE_URL/compile" \
        --output "$output_file")
    
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "200" ]; then
        if [ -f "$output_file" ]; then
            file_size=$(stat -c%s "$output_file" 2>/dev/null || stat -f%z "$output_file" 2>/dev/null || echo "unknown")
            echo "✅ Compilation successful!"
            echo "📁 Output: $output_file"
            echo "📊 Size: $file_size bytes"
            return 0
        else
            echo "❌ Compilation failed: Output file not created"
            return 1
        fi
    else
        echo "❌ Compilation failed (HTTP $http_code)"
        # Try to show error details
        if [ -f "$output_file" ]; then
            cat "$output_file" 2>/dev/null && rm -f "$output_file"
        fi
        return 1
    fi
}

# Function to format file size
format_size() {
    local bytes=$1
    if [ "$bytes" -lt 1024 ]; then
        echo "${bytes} B"
    elif [ "$bytes" -lt 1048576 ]; then
        echo "$(( bytes / 1024 )) KB"
    elif [ "$bytes" -lt 1073741824 ]; then
        echo "$(( bytes / 1048576 )) MB"
    else
        echo "$(( bytes / 1073741824 )) GB"
    fi
}

# Main script logic
case "$1" in
    health)
        check_health
        exit $?
        ;;
    compile)
        if [ -z "$2" ]; then
            echo "❌ Please provide a file path"
            show_usage
            exit 1
        fi
        compile_file "$2" "$3"
        exit $?
        ;;
    "")
        show_usage
        exit 1
        ;;
    *)
        echo "❌ Unknown command: $1"
        show_usage
        exit 1
        ;;
esac
