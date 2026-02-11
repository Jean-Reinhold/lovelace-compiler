#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

cd "$PROJECT_ROOT"

REPORT_FILE="test/TEST_REPORT.md"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

echo "Generating test report..."
echo ""

if [ ! -d "lovelace" ] || [ ! -f "lovelace/LovelaceCompiler.class" ]; then
    echo "Error: Project not compiled. Please run ./scripts/build.sh first."
    exit 1
fi

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

ERROR_TESTS=(
    "exemplo_erro" "exemplo_erro2" "exemplo_erro3" "exemplo_erro4"
    "test_erro_invalid_char" "test_erro_missing_rparen" "test_erro_missing_end_semi"
    "test_erro_missing_assign" "test_erro_keyword_as_id" "test_erro_def_no_type"
    "test_erro_empty_parens_expr" "test_erro_double_semi" "test_erro_missing_lparen_if"
    "test_erro_missing_main" "test_erro_func_after_main"
)

# Arrays to store results
declare -A LEXER_RESULTS
declare -A PARSER_RESULTS
declare -A COMPILER_RESULTS
FAILURE_DETAILS=""

LEXER_PASS=0
LEXER_FAIL=0
PARSER_PASS=0
PARSER_FAIL=0
COMPILER_PASS=0
COMPILER_FAIL=0

# ---- Run lexer tests on valid programs ----
echo "Running lexer tests..."
for test in "${VALID_TESTS[@]}"; do
    INPUT_FILE="test/examples/${test}.lov"
    EXPECTED_FILE="test/expected/${test}.out"
    ACTUAL_FILE="/tmp/${test}_report_lexer.out"

    if [ ! -f "$INPUT_FILE" ] || [ ! -f "$EXPECTED_FILE" ]; then
        LEXER_RESULTS[$test]="SKIP"
        continue
    fi

    java lovelace.Lovelace "$INPUT_FILE" > "$ACTUAL_FILE" 2>&1

    if diff -q "$EXPECTED_FILE" "$ACTUAL_FILE" > /dev/null 2>&1; then
        LEXER_RESULTS[$test]="PASS"
        LEXER_PASS=$((LEXER_PASS + 1))
    else
        LEXER_RESULTS[$test]="FAIL"
        LEXER_FAIL=$((LEXER_FAIL + 1))
        FAILURE_DETAILS="${FAILURE_DETAILS}\n### Lexer: ${test}\n\`\`\`diff\n$(diff "$EXPECTED_FILE" "$ACTUAL_FILE" | head -30)\n\`\`\`\n"
    fi
done

# ---- Run parser tests on valid programs ----
echo "Running parser tests (valid)..."
for test in "${VALID_TESTS[@]}"; do
    INPUT_FILE="test/examples/${test}.lov"
    EXPECTED_FILE="test/expected_sintatico/${test}.out"
    ACTUAL_FILE="/tmp/${test}_report_parser.out"

    if [ ! -f "$INPUT_FILE" ] || [ ! -f "$EXPECTED_FILE" ]; then
        PARSER_RESULTS[$test]="SKIP"
        continue
    fi

    java lovelace.LovelaceSintatico "$INPUT_FILE" > "$ACTUAL_FILE" 2>&1

    if diff -q "$EXPECTED_FILE" "$ACTUAL_FILE" > /dev/null 2>&1; then
        PARSER_RESULTS[$test]="PASS"
        PARSER_PASS=$((PARSER_PASS + 1))
    else
        PARSER_RESULTS[$test]="FAIL"
        PARSER_FAIL=$((PARSER_FAIL + 1))
        FAILURE_DETAILS="${FAILURE_DETAILS}\n### Parser (valid): ${test}\n\`\`\`diff\n$(diff "$EXPECTED_FILE" "$ACTUAL_FILE" | head -30)\n\`\`\`\n"
    fi
done

# ---- Run parser tests on error programs ----
echo "Running parser tests (error)..."
for test in "${ERROR_TESTS[@]}"; do
    INPUT_FILE="test/examples/${test}.lov"
    EXPECTED_FILE="test/expected_sintatico/${test}.out"
    ACTUAL_FILE="/tmp/${test}_report_parser.out"

    if [ ! -f "$INPUT_FILE" ]; then
        PARSER_RESULTS[$test]="SKIP"
        continue
    fi

    java lovelace.LovelaceSintatico "$INPUT_FILE" > "$ACTUAL_FILE" 2>&1
    EXIT_CODE=$?

    if [ $EXIT_CODE -ne 0 ]; then
        if [ -f "$EXPECTED_FILE" ] && diff -q "$EXPECTED_FILE" "$ACTUAL_FILE" > /dev/null 2>&1; then
            PARSER_RESULTS[$test]="PASS"
            PARSER_PASS=$((PARSER_PASS + 1))
        elif [ ! -f "$EXPECTED_FILE" ]; then
            PARSER_RESULTS[$test]="PASS"
            PARSER_PASS=$((PARSER_PASS + 1))
        else
            PARSER_RESULTS[$test]="FAIL"
            PARSER_FAIL=$((PARSER_FAIL + 1))
            FAILURE_DETAILS="${FAILURE_DETAILS}\n### Parser (error): ${test}\n\`\`\`diff\n$(diff "$EXPECTED_FILE" "$ACTUAL_FILE" | head -30)\n\`\`\`\n"
        fi
    else
        PARSER_RESULTS[$test]="FAIL"
        PARSER_FAIL=$((PARSER_FAIL + 1))
        FAILURE_DETAILS="${FAILURE_DETAILS}\n### Parser (error): ${test}\nExpected error but parser succeeded.\n"
    fi
done

# ---- Run compiler tests on valid programs ----
echo "Running compiler tests (valid)..."
for test in "${VALID_TESTS[@]}"; do
    INPUT_FILE="test/examples/${test}.lov"
    EXPECTED_FILE="test/expected_compiler/${test}.c"
    GENERATED_FILE="test/examples/${test}.c"

    if [ ! -f "$INPUT_FILE" ] || [ ! -f "$EXPECTED_FILE" ]; then
        COMPILER_RESULTS[$test]="SKIP"
        continue
    fi

    java lovelace.LovelaceCompiler "$INPUT_FILE" > /dev/null 2>&1
    EXIT_CODE=$?

    if [ $EXIT_CODE -ne 0 ]; then
        COMPILER_RESULTS[$test]="FAIL"
        COMPILER_FAIL=$((COMPILER_FAIL + 1))
        FAILURE_DETAILS="${FAILURE_DETAILS}\n### Compiler (valid): ${test}\nCompiler returned error exit code.\n"
        continue
    fi

    if [ -f "$GENERATED_FILE" ]; then
        if diff -q "$EXPECTED_FILE" "$GENERATED_FILE" > /dev/null 2>&1; then
            COMPILER_RESULTS[$test]="PASS"
            COMPILER_PASS=$((COMPILER_PASS + 1))
        else
            COMPILER_RESULTS[$test]="FAIL"
            COMPILER_FAIL=$((COMPILER_FAIL + 1))
            FAILURE_DETAILS="${FAILURE_DETAILS}\n### Compiler (valid): ${test}\n\`\`\`diff\n$(diff "$EXPECTED_FILE" "$GENERATED_FILE" | head -30)\n\`\`\`\n"
        fi
        rm -f "$GENERATED_FILE"
    else
        COMPILER_RESULTS[$test]="FAIL"
        COMPILER_FAIL=$((COMPILER_FAIL + 1))
        FAILURE_DETAILS="${FAILURE_DETAILS}\n### Compiler (valid): ${test}\nNo .c file generated.\n"
    fi
done

# ---- Run compiler tests on error programs ----
echo "Running compiler tests (error)..."
for test in "${ERROR_TESTS[@]}"; do
    INPUT_FILE="test/examples/${test}.lov"

    if [ ! -f "$INPUT_FILE" ]; then
        COMPILER_RESULTS[$test]="SKIP"
        continue
    fi

    java lovelace.LovelaceCompiler "$INPUT_FILE" > /dev/null 2>&1
    EXIT_CODE=$?

    if [ $EXIT_CODE -ne 0 ]; then
        COMPILER_RESULTS[$test]="PASS"
        COMPILER_PASS=$((COMPILER_PASS + 1))
    else
        COMPILER_RESULTS[$test]="FAIL"
        COMPILER_FAIL=$((COMPILER_FAIL + 1))
        FAILURE_DETAILS="${FAILURE_DETAILS}\n### Compiler (error): ${test}\nExpected error but compiler succeeded.\n"
    fi

    rm -f "test/examples/${test}.c"
done

# ---- Generate report ----
echo "Writing report to $REPORT_FILE..."

TOTAL_PASS=$((LEXER_PASS + PARSER_PASS + COMPILER_PASS))
TOTAL_FAIL=$((LEXER_FAIL + PARSER_FAIL + COMPILER_FAIL))
TOTAL=$((TOTAL_PASS + TOTAL_FAIL))

cat > "$REPORT_FILE" << HEADER
# Lovelace Compiler - Test Report

**Date:** ${TIMESTAMP}
**Branch:** ${GIT_BRANCH}
**Commit:** ${GIT_COMMIT}

## Summary

| Phase | Passed | Failed | Total |
|-------|--------|--------|-------|
| Lexer | ${LEXER_PASS} | ${LEXER_FAIL} | $((LEXER_PASS + LEXER_FAIL)) |
| Parser | ${PARSER_PASS} | ${PARSER_FAIL} | $((PARSER_PASS + PARSER_FAIL)) |
| Compiler | ${COMPILER_PASS} | ${COMPILER_FAIL} | $((COMPILER_PASS + COMPILER_FAIL)) |
| **Total** | **${TOTAL_PASS}** | **${TOTAL_FAIL}** | **${TOTAL}** |

## Valid Program Tests

| Test | Lexer | Parser | Compiler |
|------|-------|--------|----------|
HEADER

for test in "${VALID_TESTS[@]}"; do
    L=${LEXER_RESULTS[$test]:-"SKIP"}
    P=${PARSER_RESULTS[$test]:-"SKIP"}
    C=${COMPILER_RESULTS[$test]:-"SKIP"}
    echo "| ${test} | ${L} | ${P} | ${C} |" >> "$REPORT_FILE"
done

cat >> "$REPORT_FILE" << ERRHEADER

## Error Program Tests

| Test | Parser | Compiler |
|------|--------|----------|
ERRHEADER

for test in "${ERROR_TESTS[@]}"; do
    P=${PARSER_RESULTS[$test]:-"SKIP"}
    C=${COMPILER_RESULTS[$test]:-"SKIP"}
    echo "| ${test} | ${P} | ${C} |" >> "$REPORT_FILE"
done

if [ -n "$FAILURE_DETAILS" ]; then
    echo "" >> "$REPORT_FILE"
    echo "## Failure Details" >> "$REPORT_FILE"
    echo -e "$FAILURE_DETAILS" >> "$REPORT_FILE"
fi

# ---- Print summary to stdout ----
echo ""
echo "=========================================="
echo "Test Report Summary"
echo "=========================================="
echo "  Lexer:    ${LEXER_PASS} passed, ${LEXER_FAIL} failed"
echo "  Parser:   ${PARSER_PASS} passed, ${PARSER_FAIL} failed"
echo "  Compiler: ${COMPILER_PASS} passed, ${COMPILER_FAIL} failed"
echo "  -----------------------------------------"
echo "  Total:    ${TOTAL_PASS} passed, ${TOTAL_FAIL} failed out of ${TOTAL}"
echo ""

if [ $TOTAL_FAIL -eq 0 ]; then
    echo "All tests passed!"
    echo ""
    echo "Report saved to: $REPORT_FILE"
    exit 0
else
    echo "Some tests failed. See $REPORT_FILE for details."
    exit 1
fi
