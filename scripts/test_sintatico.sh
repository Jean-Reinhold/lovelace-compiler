#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

cd "$PROJECT_ROOT"

echo "Running Lovelace Syntax Analyzer Tests..."
echo "=========================================="
echo ""

if [ ! -d "lovelace" ] || [ ! -f "lovelace/LovelaceSintatico.class" ]; then
    echo "Error: Parser not compiled. Please run ./scripts/build.sh first."
    exit 1
fi

TESTS=("exemplo" "exemplo1" "exemplo2")
PASSED=0
FAILED=0

for test in "${TESTS[@]}"; do
    echo "Testing: $test.lov"
    
    INPUT_FILE="test/examples/${test}.lov"
    EXPECTED_FILE="test/expected_sintatico/${test}.out"
    ACTUAL_FILE="/tmp/${test}_sintatico_actual.out"
    
    if [ ! -f "$INPUT_FILE" ]; then
        echo "  ERROR: Input file not found: $INPUT_FILE"
        FAILED=$((FAILED + 1))
        continue
    fi
    
    java lovelace.LovelaceSintatico "$INPUT_FILE" > "$ACTUAL_FILE" 2>&1
    EXIT_CODE=$?
    
    if [ ! -f "$EXPECTED_FILE" ]; then
        echo "  ⚠ WARNING: Expected output file not found: $EXPECTED_FILE"
        echo "    Creating it with actual output..."
        mkdir -p test/expected_sintatico
        cp "$ACTUAL_FILE" "$EXPECTED_FILE"
        echo "    Actual output:"
        cat "$ACTUAL_FILE" | sed 's/^/      /'
        PASSED=$((PASSED + 1))
    else
        if [ $EXIT_CODE -eq 0 ]; then
            if grep -q "Análise sintática concluída com sucesso!" "$ACTUAL_FILE"; then
                if diff -q "$EXPECTED_FILE" "$ACTUAL_FILE" > /dev/null; then
                    echo "  ✓ PASSED"
                    PASSED=$((PASSED + 1))
                else
                    echo "  ✗ FAILED (output mismatch)"
                    echo "    Differences:"
                    diff "$EXPECTED_FILE" "$ACTUAL_FILE" | head -20 | sed 's/^/      /'
                    FAILED=$((FAILED + 1))
                fi
            else
                echo "  ✗ FAILED (no success message)"
                echo "    Actual output:"
                cat "$ACTUAL_FILE" | sed 's/^/      /'
                FAILED=$((FAILED + 1))
            fi
        else
            if diff -q "$EXPECTED_FILE" "$ACTUAL_FILE" > /dev/null; then
                echo "  ✓ PASSED (expected error)"
                PASSED=$((PASSED + 1))
            else
                echo "  ✗ FAILED (unexpected error or error mismatch)"
                echo "    Actual output:"
                cat "$ACTUAL_FILE" | sed 's/^/      /'
                echo "    Expected output:"
                cat "$EXPECTED_FILE" | sed 's/^/      /'
                FAILED=$((FAILED + 1))
            fi
        fi
    fi
    
    echo ""
done

echo "=========================================="
echo "Test Results:"
echo "  Passed: $PASSED"
echo "  Failed: $FAILED"
echo "  Total:  $((PASSED + FAILED))"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "All tests passed! ✓"
    exit 0
else
    echo "Some tests failed. ✗"
    exit 1
fi

