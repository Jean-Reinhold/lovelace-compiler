#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

cd "$PROJECT_ROOT"

if [ ! -d "lovelace" ] || [ ! -f "lovelace/LovelaceCompiler.class" ]; then
    echo "Error: Compiler not compiled. Please run ./scripts/build.sh first."
    exit 1
fi

if [ $# -eq 1 ]; then
    java lovelace.LovelaceCompiler "$1"
    exit $?
fi

echo "Lovelace Compiler - Generate C code from Lovelace programs"
echo "=========================================================="
echo ""
echo "Available test files:"
echo ""

FILES=(test/examples/*.lov)
for i in "${!FILES[@]}"; do
    echo "  $((i + 1)). ${FILES[$i]}"
done

echo ""
read -p "Select a file (1-${#FILES[@]}): " choice

if [ "$choice" -ge 1 ] && [ "$choice" -le "${#FILES[@]}" ] 2>/dev/null; then
    FILE="${FILES[$((choice - 1))]}"
    echo ""
    echo "Compiling: $FILE"
    echo "---"
    java lovelace.LovelaceCompiler "$FILE"
else
    echo "Invalid selection."
    exit 1
fi
