#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

cd "$PROJECT_ROOT"

if [ ! -d "lovelace" ] || [ ! -f "lovelace/LovelaceSintatico.class" ]; then
    echo "Error: Parser not compiled. Run ./scripts/build.sh first."
    exit 1
fi

TEST_FILES=($(find test/examples -name "*.lov" | sort))

if [ ${#TEST_FILES[@]} -eq 0 ]; then
    echo "Error: No test files found in test/examples/"
    exit 1
fi

echo "=========================================="
echo "Lovelace Syntax Analyzer - Test Runner"
echo "=========================================="
echo ""
echo "Available test cases:"
echo ""

for i in "${!TEST_FILES[@]}"; do
    filename=$(basename "${TEST_FILES[$i]}")
    echo "  $((i+1)). $filename"
done

echo ""
echo "  0. Exit"
echo ""

while true; do
    read -p "Select a test case (0-${#TEST_FILES[@]}): " choice
    
    if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
        echo "Invalid input. Please enter a number."
        continue
    fi
    
    if [ "$choice" -eq 0 ]; then
        echo "Exiting..."
        exit 0
    fi
    
    if [ "$choice" -ge 1 ] && [ "$choice" -le ${#TEST_FILES[@]} ]; then
        selected_file="${TEST_FILES[$((choice-1))]}"
        break
    else
        echo "Invalid selection. Please choose a number between 0 and ${#TEST_FILES[@]}."
    fi
done

echo ""
echo "=========================================="
echo "Parsing: $(basename "$selected_file")"
echo "=========================================="
echo ""

java lovelace.LovelaceSintatico "$selected_file"

echo ""
echo "=========================================="
echo "Parsing complete!"
echo "=========================================="

