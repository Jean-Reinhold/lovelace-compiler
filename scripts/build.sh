#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

cd "$PROJECT_ROOT"

echo "Building Lovelace Compiler..."

if ! command -v javacc &> /dev/null; then
    echo "Error: javacc command not found."
    echo "Please install JavaCC or add it to your PATH."
    echo "You can download JavaCC from: https://javacc.github.io/javacc/"
    exit 1
fi

mkdir -p src/lovelace

echo "Generating parser from src/lovelace/Lovelace.jj..."
cd src/lovelace
javacc Lovelace.jj

if [ $? -ne 0 ]; then
    echo "Error: Failed to generate parser from JavaCC grammar."
    exit 1
fi

cd ../..

echo "Compiling Java files..."
javac -d . $(find src -name "*.java")

if [ $? -ne 0 ]; then
    echo "Error: Failed to compile Java files."
    exit 1
fi

echo "Build completed successfully!"
echo ""
echo "To run the lexical analyzer:"
echo "  java lovelace.Lovelace <arquivo.lov>"
echo ""
echo "To run the syntax analyzer:"
echo "  java lovelace.LovelaceSintatico <arquivo.lov>"
echo ""
echo "To run the compiler (generates C code):"
echo "  java lovelace.LovelaceCompiler <arquivo.lov>"
echo ""
echo "Examples:"
echo "  java lovelace.LovelaceCompiler test/examples/exemplo.lov"
echo "  java lovelace.LovelaceCompiler test/examples/exemplo2.lov"
