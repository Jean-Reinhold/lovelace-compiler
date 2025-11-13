#!/bin/bash


# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

cd "$PROJECT_ROOT"

echo "Running Lovelace Lexical Analyzer Tests..."
echo "=========================================="
echo ""

if [ ! -d "lovelace" ] || [ ! -f "lovelace/Lovelace.class" ]; then
    echo "Error: Analyzer not compiled. Please run ./build.sh first."
    exit 1
fi

TESTS=("exemplo" "exemplo1" "exemplo2")
PASSED=0
FAILED=0

for test in "${TESTS[@]}"; do
    echo "Testing: $test.lov"
    
    INPUT_FILE="test/examples/${test}.lov"
    EXPECTED_FILE="test/expected/${test}.out"
    ACTUAL_FILE="/tmp/${test}_actual.out"
    
    if [ ! -f "$INPUT_FILE" ]; then
        echo "  ERROR: Input file not found: $INPUT_FILE"
        FAILED=$((FAILED + 1))
        continue
    fi
    
    if [ ! -f "$EXPECTED_FILE" ]; then
        echo "  ERROR: Expected output file not found: $EXPECTED_FILE"
        FAILED=$((FAILED + 1))
        continue
    fi
    
    java lovelace.Lovelace "$INPUT_FILE" > "$ACTUAL_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        echo "  ERROR: Analyzer failed to run"
        FAILED=$((FAILED + 1))
        continue
    fi
    
    if diff -q "$EXPECTED_FILE" "$ACTUAL_FILE" > /dev/null; then
        echo "  ✓ PASSED"
        PASSED=$((PASSED + 1))
    else
        echo "  ✗ FAILED"
        echo "    Differences:"
        diff "$EXPECTED_FILE" "$ACTUAL_FILE" | head -20 | sed 's/^/      /'
        FAILED=$((FAILED + 1))
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

