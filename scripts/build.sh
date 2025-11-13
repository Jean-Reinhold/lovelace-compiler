#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

cd "$PROJECT_ROOT"

echo "Building Lovelace Lexical Analyzer..."

if ! command -v javacc &> /dev/null; then
    echo "Error: javacc command not found."
    echo "Please install JavaCC or add it to your PATH."
    echo "You can download JavaCC from: https://javacc.github.io/javacc/"
    exit 1
fi

mkdir -p src/lovelace

echo "Generating lexer from src/lovelace/Lovelace.jj..."
cd src/lovelace
javacc Lovelace.jj

if [ $? -ne 0 ]; then
    echo "Error: Failed to generate lexer from JavaCC grammar."
    exit 1
fi

cd ../..

echo "Compiling Java files..."
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

