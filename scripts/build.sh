#!/bin/bash

# Build script for Lovelace Lexical Analyzer

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Get the project root directory (parent of scripts)
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Change to project root
cd "$PROJECT_ROOT"

echo "Building Lovelace Lexical Analyzer..."

# Check if javacc is available
if ! command -v javacc &> /dev/null; then
    echo "Error: javacc command not found."
    echo "Please install JavaCC or add it to your PATH."
    echo "You can download JavaCC from: https://javacc.github.io/javacc/"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p src/lovelace

# Generate Java files from JavaCC grammar
echo "Generating lexer from src/lovelace/Lovelace.jj..."
cd src/lovelace
javacc Lovelace.jj

if [ $? -ne 0 ]; then
    echo "Error: Failed to generate lexer from JavaCC grammar."
    exit 1
fi

cd ../..

# Compile Java files (including generated ones)
echo "Compiling Java files..."
# Compile all Java files in the lovelace directory together
javac -d . $(find src/lovelace -name "*.java")

if [ $? -ne 0 ]; then
    echo "Error: Failed to compile Java files."
    exit 1
fi

echo "Build completed successfully!"
echo ""
echo "To run the analyzer, use:"
echo "  java lovelace.Lovelace <arquivo.lov>"
echo ""
echo "Examples:"
echo "  java lovelace.Lovelace test/examples/exemplo.lov"
echo "  java lovelace.Lovelace test/examples/exemplo1.lov"
echo "  java lovelace.Lovelace test/examples/exemplo2.lov"

