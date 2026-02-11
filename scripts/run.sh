#!/bin/bash
# run.sh -- Unified interactive runner for Lovelace compiler phases.
#
# Usage:
#   ./scripts/run.sh [lexer|parser|compiler] [FILE]
#
# If no phase is given, runs all three phases on the file.
# If no FILE is given, shows an interactive menu.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

cd "$PROJECT_ROOT"

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
PHASE=""
FILE=""

for arg in "$@"; do
    case "$arg" in
        lexer|parser|compiler) PHASE="$arg" ;;
        *) FILE="$arg" ;;
    esac
done

# ---------------------------------------------------------------------------
# Auto-build if needed
# ---------------------------------------------------------------------------
if [ ! -d "lovelace" ] || [ ! -f "lovelace/Lovelace.class" ]; then
    echo "Classes not found. Building automatically..."
    bash "${SCRIPT_DIR}/build.sh" -q
    if [ $? -ne 0 ]; then
        echo "Error: Auto-build failed. Please run ./scripts/build.sh manually."
        exit 1
    fi
    echo ""
fi

# ---------------------------------------------------------------------------
# Interactive file selection if no FILE given
# ---------------------------------------------------------------------------
if [ -z "$FILE" ]; then
    TEST_FILES=($(find test/examples -name "*.lov" 2>/dev/null | sort))

    if [ ${#TEST_FILES[@]} -eq 0 ]; then
        echo "Error: No test files found in test/examples/"
        exit 1
    fi

    echo "=========================================="
    echo "Lovelace Compiler - Interactive Runner"
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
            FILE="${TEST_FILES[$((choice-1))]}"
            break
        else
            echo "Invalid selection. Please choose a number between 0 and ${#TEST_FILES[@]}."
        fi
    done
fi

# Validate file exists
if [ ! -f "$FILE" ]; then
    echo "Error: File not found: $FILE"
    exit 1
fi

# ---------------------------------------------------------------------------
# Run phase(s)
# ---------------------------------------------------------------------------
run_lexer() {
    echo "=========================================="
    echo "Lexical Analysis: $(basename "$FILE")"
    echo "=========================================="
    echo ""
    java lovelace.Lovelace "$FILE"
    echo ""
}

run_parser() {
    echo "=========================================="
    echo "Syntax Analysis: $(basename "$FILE")"
    echo "=========================================="
    echo ""
    java lovelace.LovelaceSintatico "$FILE"
    echo ""
}

run_compiler() {
    echo "=========================================="
    echo "Compilation: $(basename "$FILE")"
    echo "=========================================="
    echo ""
    java lovelace.LovelaceCompiler "$FILE"
    local EC=$?
    echo ""

    # Show generated C file if it exists
    local BASE=$(basename "$FILE" .lov)
    local DIR=$(dirname "$FILE")
    local C_FILE="${DIR}/${BASE}.c"
    if [ -f "$C_FILE" ]; then
        echo "--- Generated C code (${C_FILE}) ---"
        cat -n "$C_FILE"
        echo ""
    fi

    return $EC
}

run_phase() {
    case "$1" in
        lexer)    run_lexer ;;
        parser)   run_parser ;;
        compiler) run_compiler ;;
    esac
}

output() {
    if [ -n "$PHASE" ]; then
        run_phase "$PHASE"
    else
        run_lexer
        run_parser
        run_compiler
    fi
}

if [ -t 1 ]; then
    output 2>&1 | less -R
else
    output
fi
