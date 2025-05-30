#!/bin/bash

echo "MQ5 Compiler Service - Mock Compiler"
echo "Arguments: $@"

# Parse arguments
INPUT_FILE=""
OUTPUT_FILE=""

for ((i=1; i<=$#; i++)); do
    case "${!i}" in
        /compile)
            # Next argument should be input file
            j=$((i+1))
            INPUT_FILE="${!j}"
            ;;
        /out:*)
            # Extract output file path
            OUTPUT_FILE="${!i#/out:}"
            ;;
    esac
done

echo "Input file: $INPUT_FILE"
echo "Output file: $OUTPUT_FILE"

# Simple compilation simulation
if [ -f "$INPUT_FILE" ] && [ -n "$OUTPUT_FILE" ]; then
    # Create output directory if it doesn't exist
    mkdir -p "$(dirname "$OUTPUT_FILE")"
    
    # Generate a mock compiled file with binary-like content
    # This simulates what a real compiler would produce
    {
        # Add some binary header-like data
        echo -ne '\x4D\x51\x35\x00'  # MQ5 signature
        echo -ne '\x01\x00\x00\x00'  # Version
        echo -ne '\x00\x10\x00\x00'  # Size placeholder
        
        # Add some "compiled" metadata
        echo "// Compiled Expert Advisor"
        echo "// Source: $(basename "$INPUT_FILE")"
        echo "// Compiled on: $(date)"
        echo "// Mock compilation successful"
        echo ""
        
        # Add some binary-looking data
        for i in {1..50}; do
            echo -ne "\x$(printf '%02x' $((RANDOM % 256)))"
        done
        
        # Add the original source as "debug information" (commented out)
        echo ""
        echo "/* Original source (debug info):"
        sed 's/^/ * /' "$INPUT_FILE"
        echo " */"
        
        # More binary-like data
        for i in {1..30}; do
            echo -ne "\x$(printf '%02x' $((RANDOM % 256)))"
        done
        
    } > "$OUTPUT_FILE"
    
    # Ensure .ex5 extension
    if [[ "$OUTPUT_FILE" != *.ex5 ]]; then
        mv "$OUTPUT_FILE" "${OUTPUT_FILE%.mq*}.ex5"
        OUTPUT_FILE="${OUTPUT_FILE%.mq*}.ex5"
    fi
    
    echo "Compilation completed successfully"
    echo "Generated: $OUTPUT_FILE"
    echo "File size: $(stat -c%s "$OUTPUT_FILE" 2>/dev/null || echo "unknown") bytes"
    exit 0
else
    echo "Error: Invalid input file or output path"
    echo "Input file exists: $([ -f "$INPUT_FILE" ] && echo "yes" || echo "no")"
    echo "Output path provided: $([ -n "$OUTPUT_FILE" ] && echo "yes" || echo "no")"
    exit 1
fi
