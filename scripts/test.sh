#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

cd "$PROJECT_ROOT"

echo "Running Lovelace Lexical Analyzer Tests..."
echo "=========================================="
echo ""

if [ ! -d "lovelace" ] || [ ! -f "lovelace/Lovelace.class" ]; then
    echo "Error: Analyzer not compiled. Run ./scripts/build.sh first."
    exit 1
fi

TESTS=(
    "exemplo" "exemplo1" "exemplo2" "exemplo3" "exemplo4"
    "exemplo_empty" "exemplo_nested" "exemplo_funcall_stmt"
    "exemplo_bool_ops" "exemplo_scientific" "exemplo_multiparams"
    "exemplo_void_return"
    "test_id_underscore" "test_id_multi_underscore" "test_id_mixed_case"
    "test_num_integer" "test_num_scientific_signs" "test_num_variety"
    "test_op_arithmetic" "test_op_comparison" "test_op_logical"
    "test_prec_arith" "test_prec_bool" "test_prec_mixed"
    "test_expr_nested_parens" "test_expr_funcall_in_expr" "test_expr_bool_literals_in_expr"
    "test_cmd_empty_blocks" "test_cmd_sequential_control" "test_cmd_print_expressions"
    "test_func_bool_params" "test_func_mixed_params" "test_func_chain_calls"
    "test_func_no_params_expr"
    "test_edge_only_decls" "test_edge_many_funcs"
)

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
        echo "  WARNING: Expected output not found: $EXPECTED_FILE"
        echo "    Creating it with actual output..."
        mkdir -p test/expected
        java lovelace.Lovelace "$INPUT_FILE" > "$EXPECTED_FILE" 2>&1
        echo "    Created expected output."
        PASSED=$((PASSED + 1))
        continue
    fi

    java lovelace.Lovelace "$INPUT_FILE" > "$ACTUAL_FILE" 2>&1

    if [ $? -ne 0 ]; then
        echo "  ERROR: Analyzer failed to run"
        FAILED=$((FAILED + 1))
        continue
    fi

    if diff -q "$EXPECTED_FILE" "$ACTUAL_FILE" > /dev/null; then
        echo "  PASSED"
        PASSED=$((PASSED + 1))
    else
        echo "  FAILED"
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
    echo "All tests passed!"
    exit 0
else
    echo "Some tests failed."
    exit 1
fi
