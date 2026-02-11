#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

cd "$PROJECT_ROOT"

echo "Generating expected test outputs..."
echo "=========================================="
echo ""

# Build first
if [ ! -d "lovelace" ] || [ ! -f "lovelace/Lovelace.class" ]; then
    echo "Building project first..."
    bash scripts/build.sh
    if [ $? -ne 0 ]; then
        echo "Error: Build failed."
        exit 1
    fi
    echo ""
fi

mkdir -p test/expected
mkdir -p test/expected_sintatico
mkdir -p test/expected_compiler

source "${SCRIPT_DIR}/test_discover.sh"

GENERATED=0
SKIPPED=0

echo "--- Generating valid test expected outputs ---"
echo ""

for test in "${VALID_TESTS[@]}"; do
    INPUT_FILE="test/examples/${test}.lov"

    if [ ! -f "$INPUT_FILE" ]; then
        echo "  WARNING: Input file not found: $INPUT_FILE"
        continue
    fi

    # Lexer expected output
    LEXER_FILE="test/expected/${test}.out"
    if [ ! -f "$LEXER_FILE" ]; then
        java lovelace.Lovelace "$INPUT_FILE" > "$LEXER_FILE" 2>&1
        echo "  Created: $LEXER_FILE"
        GENERATED=$((GENERATED + 1))
    else
        SKIPPED=$((SKIPPED + 1))
    fi

    # Parser expected output
    PARSER_FILE="test/expected_sintatico/${test}.out"
    if [ ! -f "$PARSER_FILE" ]; then
        java lovelace.LovelaceSintatico "$INPUT_FILE" > "$PARSER_FILE" 2>&1
        echo "  Created: $PARSER_FILE"
        GENERATED=$((GENERATED + 1))
    else
        SKIPPED=$((SKIPPED + 1))
    fi

    # Compiler expected output
    COMPILER_FILE="test/expected_compiler/${test}.c"
    if [ ! -f "$COMPILER_FILE" ]; then
        java lovelace.LovelaceCompiler "$INPUT_FILE" > /dev/null 2>&1
        GENERATED_C="test/examples/${test}.c"
        if [ -f "$GENERATED_C" ]; then
            cp "$GENERATED_C" "$COMPILER_FILE"
            rm -f "$GENERATED_C"
            echo "  Created: $COMPILER_FILE"
            GENERATED=$((GENERATED + 1))
        else
            echo "  WARNING: Compiler did not generate C file for $test"
        fi
    else
        SKIPPED=$((SKIPPED + 1))
    fi
done

echo ""
echo "--- Generating error test expected outputs ---"
echo ""

for test in "${ERROR_TESTS[@]}"; do
    INPUT_FILE="test/examples/${test}.lov"

    if [ ! -f "$INPUT_FILE" ]; then
        echo "  WARNING: Input file not found: $INPUT_FILE"
        continue
    fi

    # Parser expected output (error message)
    PARSER_FILE="test/expected_sintatico/${test}.out"
    if [ ! -f "$PARSER_FILE" ]; then
        java lovelace.LovelaceSintatico "$INPUT_FILE" > "$PARSER_FILE" 2>&1
        echo "  Created: $PARSER_FILE"
        GENERATED=$((GENERATED + 1))
    else
        SKIPPED=$((SKIPPED + 1))
    fi

    # Clean up any accidentally generated .c files
    rm -f "test/examples/${test}.c"
done

echo ""
echo "=========================================="
echo "Generated: $GENERATED files"
echo "Skipped (already exist): $SKIPPED files"
echo "Done!"
