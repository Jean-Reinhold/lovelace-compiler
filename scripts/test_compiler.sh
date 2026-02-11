#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

cd "$PROJECT_ROOT"

echo "Running Lovelace Compiler Tests..."
echo "=========================================="
echo ""

if [ ! -d "lovelace" ] || [ ! -f "lovelace/LovelaceCompiler.class" ]; then
    echo "Error: Compiler not compiled. Please run ./scripts/build.sh first."
    exit 1
fi

PASSED=0
FAILED=0

# Valid programs - compile and compare generated C with expected output
VALID_TESTS=(
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

for test in "${VALID_TESTS[@]}"; do
    echo "Testing: $test.lov"

    INPUT_FILE="test/examples/${test}.lov"
    EXPECTED_FILE="test/expected_compiler/${test}.c"
    GENERATED_FILE="test/examples/${test}.c"

    if [ ! -f "$INPUT_FILE" ]; then
        echo "  ERROR: Input file not found: $INPUT_FILE"
        FAILED=$((FAILED + 1))
        continue
    fi

    # Run compiler
    OUTPUT=$(java lovelace.LovelaceCompiler "$INPUT_FILE" 2>&1)
    EXIT_CODE=$?

    if [ $EXIT_CODE -ne 0 ]; then
        echo "  FAILED (compiler error)"
        echo "    $OUTPUT"
        FAILED=$((FAILED + 1))
        continue
    fi

    if [ ! -f "$GENERATED_FILE" ]; then
        echo "  FAILED (no .c file generated)"
        FAILED=$((FAILED + 1))
        continue
    fi

    # Compare with expected output
    if [ ! -f "$EXPECTED_FILE" ]; then
        echo "  WARNING: Expected output not found: $EXPECTED_FILE"
        echo "    Creating it with actual output..."
        mkdir -p test/expected_compiler
        cp "$GENERATED_FILE" "$EXPECTED_FILE"
        PASSED=$((PASSED + 1))
    else
        if diff -q "$EXPECTED_FILE" "$GENERATED_FILE" > /dev/null 2>&1; then
            echo "  PASSED"
            PASSED=$((PASSED + 1))
        else
            echo "  FAILED (output mismatch)"
            echo "    Differences:"
            diff "$EXPECTED_FILE" "$GENERATED_FILE" | head -20 | sed 's/^/      /'
            FAILED=$((FAILED + 1))
        fi
    fi

    # Verify generated C compiles with gcc (if available)
    if command -v gcc &> /dev/null; then
        GCC_OUTPUT=$(gcc -fsyntax-only -Wno-format "$GENERATED_FILE" 2>&1)
        if [ $? -ne 0 ]; then
            echo "  WARNING: Generated C has syntax errors:"
            echo "    $GCC_OUTPUT"
        fi
    fi

    # Clean up generated file
    rm -f "$GENERATED_FILE"

    echo ""
done

# Error programs - verify they produce parse errors
ERROR_TESTS=(
    "exemplo_erro" "exemplo_erro2" "exemplo_erro3" "exemplo_erro4"
    "test_erro_invalid_char" "test_erro_missing_rparen" "test_erro_missing_end_semi"
    "test_erro_missing_assign" "test_erro_keyword_as_id" "test_erro_def_no_type"
    "test_erro_empty_parens_expr" "test_erro_double_semi" "test_erro_missing_lparen_if"
    "test_erro_missing_main" "test_erro_func_after_main"
)

echo "--- Error Tests ---"
echo ""

for test in "${ERROR_TESTS[@]}"; do
    echo "Testing: $test.lov (should fail)"

    INPUT_FILE="test/examples/${test}.lov"

    if [ ! -f "$INPUT_FILE" ]; then
        echo "  ERROR: Input file not found: $INPUT_FILE"
        FAILED=$((FAILED + 1))
        continue
    fi

    OUTPUT=$(java lovelace.LovelaceCompiler "$INPUT_FILE" 2>&1)
    EXIT_CODE=$?

    if [ $EXIT_CODE -ne 0 ]; then
        echo "  PASSED (correctly reported error)"
        PASSED=$((PASSED + 1))
    else
        echo "  FAILED (should have reported an error)"
        FAILED=$((FAILED + 1))
    fi

    # Clean up any accidentally generated file
    rm -f "test/examples/${test}.c"

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
