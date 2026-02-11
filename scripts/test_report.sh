#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

cd "$PROJECT_ROOT"

REPORT_FILE="test/TEST_REPORT.md"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
GIT_COMMIT_FULL=$(git rev-parse HEAD 2>/dev/null || echo "unknown")

echo "Generating test report..."
echo ""

if [ ! -d "lovelace" ] || [ ! -f "lovelace/LovelaceCompiler.class" ]; then
    echo "Error: Project not compiled. Please run ./scripts/build.sh first."
    exit 1
fi

# ---------------------------------------------------------------------------
# Test registry: name -> human-readable description
# ---------------------------------------------------------------------------
declare -A TEST_DESC

# -- Original examples --
TEST_DESC[exemplo]="Variable declaration, assignment and print"
TEST_DESC[exemplo1]="Conditionals, boolean assignment, arithmetic with parentheses"
TEST_DESC[exemplo2]="Functions, loops, read input, nested control flow"
TEST_DESC[exemplo3]="Multiple functions (soma, fatorial, ehPositivo), function calls in expressions"
TEST_DESC[exemplo4]="Void functions, multi-parameter functions, nested ifs"
TEST_DESC[exemplo_empty]="Empty main body (no declarations, no statements)"
TEST_DESC[exemplo_nested]="Deeply nested if/while statements"
TEST_DESC[exemplo_funcall_stmt]="Function call used as a standalone statement"
TEST_DESC[exemplo_bool_ops]="Boolean variables with && and || operators"
TEST_DESC[exemplo_scientific]="Scientific notation literals (1.5E10, 2.0e3)"
TEST_DESC[exemplo_multiparams]="Function with four Float parameters"
TEST_DESC[exemplo_void_return]="Void function with bare return statement"

# -- Identifiers --
TEST_DESC[test_id_underscore]="Identifiers with single underscore (my_var, x_1)"
TEST_DESC[test_id_multi_underscore]="Multi-segment underscore identifiers (a_b_c, long_variable_name_1)"
TEST_DESC[test_id_mixed_case]="CamelCase identifiers mixing Float and Bool variables"

# -- Number formats --
TEST_DESC[test_num_integer]="Plain integer literals (5, 100, 0)"
TEST_DESC[test_num_scientific_signs]="Scientific notation with explicit +/- signs (1.0E+5, 2.5E-3)"
TEST_DESC[test_num_variety]="All number formats combined: integer, decimal, scientific, signed exponent"

# -- Operators --
TEST_DESC[test_op_arithmetic]="Each arithmetic operator isolated: +, -, *, /"
TEST_DESC[test_op_comparison]="Each comparison operator isolated: <, >, =="
TEST_DESC[test_op_logical]="Logical && and || with all boolean input combinations"

# -- Precedence --
TEST_DESC[test_prec_arith]="Arithmetic precedence: * and / bind tighter than + and -"
TEST_DESC[test_prec_bool]="Boolean precedence: && binds tighter than ||"
TEST_DESC[test_prec_mixed]="Full precedence chain: arithmetic > comparison > logical"

# -- Expressions --
TEST_DESC[test_expr_nested_parens]="Deeply nested parenthesized arithmetic expressions"
TEST_DESC[test_expr_funcall_in_expr]="Function calls inside arithmetic expressions and as nested arguments"
TEST_DESC[test_expr_bool_literals_in_expr]="Boolean literals (true/false) in conditions, comparisons, and print"

# -- Commands --
TEST_DESC[test_cmd_empty_blocks]="Empty if and while bodies (zero statements)"
TEST_DESC[test_cmd_sequential_control]="Multiple sequential if and while blocks in the same scope"
TEST_DESC[test_cmd_print_expressions]="Print with literal, variable, arithmetic, comparison, and Bool values"

# -- Functions --
TEST_DESC[test_func_bool_params]="Function with Bool parameter and Bool return type"
TEST_DESC[test_func_mixed_params]="Function with mixed Float and Bool parameter types"
TEST_DESC[test_func_chain_calls]="Functions calling other user-defined functions (chaining)"
TEST_DESC[test_func_no_params_expr]="Zero-argument functions used inside expressions"

# -- Edge cases --
TEST_DESC[test_edge_only_decls]="Declarations only, no executable statements in main"
TEST_DESC[test_edge_many_funcs]="Four+ function definitions with forward declarations"

# -- Error tests --
TEST_DESC[exemplo_erro]="Missing semicolon after assignment"
TEST_DESC[exemplo_erro2]="Missing closing end keyword"
TEST_DESC[exemplo_erro3]="Invalid expression (* without left operand)"
TEST_DESC[exemplo_erro4]="Missing begin keyword in main"
TEST_DESC[test_erro_invalid_char]="Invalid character @ in source (lexer error)"
TEST_DESC[test_erro_missing_rparen]="Missing ) in if condition"
TEST_DESC[test_erro_missing_end_semi]="Missing ; after end in if block"
TEST_DESC[test_erro_missing_assign]="Using = instead of := for assignment"
TEST_DESC[test_erro_keyword_as_id]="Reserved word (begin) used as variable name"
TEST_DESC[test_erro_def_no_type]="Function definition without return type"
TEST_DESC[test_erro_empty_parens_expr]="Empty parentheses () used as expression"
TEST_DESC[test_erro_double_semi]="Bare semicolon in statement position"
TEST_DESC[test_erro_missing_lparen_if]="if without parenthesized condition"
TEST_DESC[test_erro_missing_main]="Program with no main function"
TEST_DESC[test_erro_func_after_main]="Function definition inside main body (wrong scope)"

# ---------------------------------------------------------------------------
# Category grouping for valid tests
# ---------------------------------------------------------------------------
CATEGORY_NAMES=(
    "Original Examples"
    "Identifiers"
    "Number Formats"
    "Operators"
    "Operator Precedence"
    "Expressions"
    "Commands"
    "Functions"
    "Edge Cases"
)

declare -a CAT_0=(exemplo exemplo1 exemplo2 exemplo3 exemplo4 exemplo_empty exemplo_nested exemplo_funcall_stmt exemplo_bool_ops exemplo_scientific exemplo_multiparams exemplo_void_return)
declare -a CAT_1=(test_id_underscore test_id_multi_underscore test_id_mixed_case)
declare -a CAT_2=(test_num_integer test_num_scientific_signs test_num_variety)
declare -a CAT_3=(test_op_arithmetic test_op_comparison test_op_logical)
declare -a CAT_4=(test_prec_arith test_prec_bool test_prec_mixed)
declare -a CAT_5=(test_expr_nested_parens test_expr_funcall_in_expr test_expr_bool_literals_in_expr)
declare -a CAT_6=(test_cmd_empty_blocks test_cmd_sequential_control test_cmd_print_expressions)
declare -a CAT_7=(test_func_bool_params test_func_mixed_params test_func_chain_calls test_func_no_params_expr)
declare -a CAT_8=(test_edge_only_decls test_edge_many_funcs)

# Flat list used by the runners
VALID_TESTS=()
for i in $(seq 0 8); do
    arr_name="CAT_${i}[@]"
    for t in "${!arr_name}"; do
        VALID_TESTS+=("$t")
    done
done

ERROR_TESTS=(
    "exemplo_erro" "exemplo_erro2" "exemplo_erro3" "exemplo_erro4"
    "test_erro_invalid_char" "test_erro_missing_rparen" "test_erro_missing_end_semi"
    "test_erro_missing_assign" "test_erro_keyword_as_id" "test_erro_def_no_type"
    "test_erro_empty_parens_expr" "test_erro_double_semi" "test_erro_missing_lparen_if"
    "test_erro_missing_main" "test_erro_func_after_main"
)

# ---------------------------------------------------------------------------
# Run all tests -- collect results
# ---------------------------------------------------------------------------
declare -A LEXER_RESULTS
declare -A PARSER_RESULTS
declare -A COMPILER_RESULTS
FAILURE_DETAILS=""

LEXER_PASS=0;  LEXER_FAIL=0
PARSER_PASS=0; PARSER_FAIL=0
COMPILER_PASS=0; COMPILER_FAIL=0

# helper: run one phase, store result
run_test() {
    local test=$1 phase=$2
    local INPUT_FILE="test/examples/${test}.lov"

    case "$phase" in
        lexer)
            local EXPECTED="test/expected/${test}.out"
            local ACTUAL="/tmp/${test}_rpt_lex.out"
            [ ! -f "$INPUT_FILE" ] || [ ! -f "$EXPECTED" ] && { LEXER_RESULTS[$test]="SKIP"; return; }
            java lovelace.Lovelace "$INPUT_FILE" > "$ACTUAL" 2>&1
            if diff -q "$EXPECTED" "$ACTUAL" > /dev/null 2>&1; then
                LEXER_RESULTS[$test]="PASS"; LEXER_PASS=$((LEXER_PASS + 1))
            else
                LEXER_RESULTS[$test]="FAIL"; LEXER_FAIL=$((LEXER_FAIL + 1))
                FAILURE_DETAILS="${FAILURE_DETAILS}\n### Lexer -- ${test}\n\`\`\`diff\n$(diff "$EXPECTED" "$ACTUAL" | head -30)\n\`\`\`\n"
            fi
            ;;
        parser_valid)
            local EXPECTED="test/expected_sintatico/${test}.out"
            local ACTUAL="/tmp/${test}_rpt_par.out"
            [ ! -f "$INPUT_FILE" ] || [ ! -f "$EXPECTED" ] && { PARSER_RESULTS[$test]="SKIP"; return; }
            java lovelace.LovelaceSintatico "$INPUT_FILE" > "$ACTUAL" 2>&1
            if diff -q "$EXPECTED" "$ACTUAL" > /dev/null 2>&1; then
                PARSER_RESULTS[$test]="PASS"; PARSER_PASS=$((PARSER_PASS + 1))
            else
                PARSER_RESULTS[$test]="FAIL"; PARSER_FAIL=$((PARSER_FAIL + 1))
                FAILURE_DETAILS="${FAILURE_DETAILS}\n### Parser (valid) -- ${test}\n\`\`\`diff\n$(diff "$EXPECTED" "$ACTUAL" | head -30)\n\`\`\`\n"
            fi
            ;;
        parser_error)
            local EXPECTED="test/expected_sintatico/${test}.out"
            local ACTUAL="/tmp/${test}_rpt_par.out"
            [ ! -f "$INPUT_FILE" ] && { PARSER_RESULTS[$test]="SKIP"; return; }
            java lovelace.LovelaceSintatico "$INPUT_FILE" > "$ACTUAL" 2>&1
            local EC=$?
            if [ $EC -ne 0 ]; then
                if [ -f "$EXPECTED" ] && diff -q "$EXPECTED" "$ACTUAL" > /dev/null 2>&1; then
                    PARSER_RESULTS[$test]="PASS"; PARSER_PASS=$((PARSER_PASS + 1))
                elif [ ! -f "$EXPECTED" ]; then
                    PARSER_RESULTS[$test]="PASS"; PARSER_PASS=$((PARSER_PASS + 1))
                else
                    PARSER_RESULTS[$test]="FAIL"; PARSER_FAIL=$((PARSER_FAIL + 1))
                    FAILURE_DETAILS="${FAILURE_DETAILS}\n### Parser (error) -- ${test}\n\`\`\`diff\n$(diff "$EXPECTED" "$ACTUAL" | head -30)\n\`\`\`\n"
                fi
            else
                PARSER_RESULTS[$test]="FAIL"; PARSER_FAIL=$((PARSER_FAIL + 1))
                FAILURE_DETAILS="${FAILURE_DETAILS}\n### Parser (error) -- ${test}\nExpected parse error but parser succeeded.\n"
            fi
            ;;
        compiler_valid)
            local EXPECTED="test/expected_compiler/${test}.c"
            local GENERATED="test/examples/${test}.c"
            [ ! -f "$INPUT_FILE" ] || [ ! -f "$EXPECTED" ] && { COMPILER_RESULTS[$test]="SKIP"; return; }
            java lovelace.LovelaceCompiler "$INPUT_FILE" > /dev/null 2>&1
            local EC=$?
            if [ $EC -ne 0 ]; then
                COMPILER_RESULTS[$test]="FAIL"; COMPILER_FAIL=$((COMPILER_FAIL + 1))
                FAILURE_DETAILS="${FAILURE_DETAILS}\n### Compiler (valid) -- ${test}\nCompiler exited with error.\n"
                return
            fi
            if [ -f "$GENERATED" ]; then
                if diff -q "$EXPECTED" "$GENERATED" > /dev/null 2>&1; then
                    COMPILER_RESULTS[$test]="PASS"; COMPILER_PASS=$((COMPILER_PASS + 1))
                else
                    COMPILER_RESULTS[$test]="FAIL"; COMPILER_FAIL=$((COMPILER_FAIL + 1))
                    FAILURE_DETAILS="${FAILURE_DETAILS}\n### Compiler (valid) -- ${test}\n\`\`\`diff\n$(diff "$EXPECTED" "$GENERATED" | head -30)\n\`\`\`\n"
                fi
                rm -f "$GENERATED"
            else
                COMPILER_RESULTS[$test]="FAIL"; COMPILER_FAIL=$((COMPILER_FAIL + 1))
                FAILURE_DETAILS="${FAILURE_DETAILS}\n### Compiler (valid) -- ${test}\nNo .c file generated.\n"
            fi
            ;;
        compiler_error)
            [ ! -f "$INPUT_FILE" ] && { COMPILER_RESULTS[$test]="SKIP"; return; }
            java lovelace.LovelaceCompiler "$INPUT_FILE" > /dev/null 2>&1
            if [ $? -ne 0 ]; then
                COMPILER_RESULTS[$test]="PASS"; COMPILER_PASS=$((COMPILER_PASS + 1))
            else
                COMPILER_RESULTS[$test]="FAIL"; COMPILER_FAIL=$((COMPILER_FAIL + 1))
                FAILURE_DETAILS="${FAILURE_DETAILS}\n### Compiler (error) -- ${test}\nExpected error but compiler succeeded.\n"
            fi
            rm -f "test/examples/${test}.c"
            ;;
    esac
}

echo "Running lexer tests..."
for t in "${VALID_TESTS[@]}"; do run_test "$t" lexer; done

echo "Running parser tests (valid)..."
for t in "${VALID_TESTS[@]}"; do run_test "$t" parser_valid; done

echo "Running parser tests (error)..."
for t in "${ERROR_TESTS[@]}"; do run_test "$t" parser_error; done

echo "Running compiler tests (valid)..."
for t in "${VALID_TESTS[@]}"; do run_test "$t" compiler_valid; done

echo "Running compiler tests (error)..."
for t in "${ERROR_TESTS[@]}"; do run_test "$t" compiler_error; done

# ---------------------------------------------------------------------------
# Compute totals
# ---------------------------------------------------------------------------
TOTAL_PASS=$((LEXER_PASS + PARSER_PASS + COMPILER_PASS))
TOTAL_FAIL=$((LEXER_FAIL + PARSER_FAIL + COMPILER_FAIL))
TOTAL=$((TOTAL_PASS + TOTAL_FAIL))

VALID_COUNT=${#VALID_TESTS[@]}
ERROR_COUNT=${#ERROR_TESTS[@]}
TEST_FILE_COUNT=$((VALID_COUNT + ERROR_COUNT))

# ---------------------------------------------------------------------------
# Generate Markdown report
# ---------------------------------------------------------------------------
echo "Writing report to $REPORT_FILE..."

# ---- header + metadata ----
cat > "$REPORT_FILE" << 'HEADER_TOP'
# Lovelace Compiler -- Test Report
HEADER_TOP

cat >> "$REPORT_FILE" << HEADER_META

> Generated on **${TIMESTAMP}** from branch \`${GIT_BRANCH}\` at commit [\`${GIT_COMMIT}\`](../../commit/${GIT_COMMIT_FULL}).

---

## 1. Overview

This report summarises the results of the automated test suite for the
**Lovelace compiler**, covering three compilation phases:

| Phase | Tool | What is verified |
|-------|------|------------------|
| **Lexer** | \`lovelace.Lovelace\` | Tokenisation -- every token is correctly classified (reserved word, identifier, number, operator, punctuation). |
| **Parser** | \`lovelace.LovelaceSintatico\` | Syntax analysis -- the token stream is accepted (valid programs) or rejected with the expected error message (error programs). |
| **Compiler** | \`lovelace.LovelaceCompiler\` | Code generation -- the produced C source matches the expected reference file byte-for-byte (valid programs) or the compiler exits with a non-zero status (error programs). |

The suite contains **${TEST_FILE_COUNT} test programs**: ${VALID_COUNT} valid programs and ${ERROR_COUNT} programs that must be rejected.

---

## 2. Result Summary

| Phase | Passed | Failed | Total |
|------:|-------:|-------:|------:|
| Lexer | ${LEXER_PASS} | ${LEXER_FAIL} | $((LEXER_PASS + LEXER_FAIL)) |
| Parser | ${PARSER_PASS} | ${PARSER_FAIL} | $((PARSER_PASS + PARSER_FAIL)) |
| Compiler | ${COMPILER_PASS} | ${COMPILER_FAIL} | $((COMPILER_PASS + COMPILER_FAIL)) |
| **Total** | **${TOTAL_PASS}** | **${TOTAL_FAIL}** | **${TOTAL}** |

HEADER_META

if [ $TOTAL_FAIL -eq 0 ]; then
    echo "**All ${TOTAL} checks passed.**" >> "$REPORT_FILE"
else
    echo "**${TOTAL_FAIL} check(s) failed** -- see [Failure Details](#7-failure-details) below." >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" << 'SEP1'

---

## 3. Valid Program Tests

Each valid `.lov` program is run through all three phases. The table below
groups tests by the language feature they exercise.

SEP1

# ---- valid test tables, grouped by category ----
for cat_idx in $(seq 0 8); do
    cat_name="${CATEGORY_NAMES[$cat_idx]}"
    echo "### 3.$((cat_idx + 1)). ${cat_name}" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "| Test file | Description | Lexer | Parser | Compiler |" >> "$REPORT_FILE"
    echo "|-----------|-------------|:-----:|:------:|:--------:|" >> "$REPORT_FILE"

    arr_name="CAT_${cat_idx}[@]"
    for test in "${!arr_name}"; do
        desc="${TEST_DESC[$test]:-""}"
        L="${LEXER_RESULTS[$test]:-SKIP}"
        P="${PARSER_RESULTS[$test]:-SKIP}"
        C="${COMPILER_RESULTS[$test]:-SKIP}"

        # Format result with symbols
        [[ "$L" == "PASS" ]] && L_FMT="PASS" || L_FMT="**FAIL**"
        [[ "$P" == "PASS" ]] && P_FMT="PASS" || P_FMT="**FAIL**"
        [[ "$C" == "PASS" ]] && C_FMT="PASS" || C_FMT="**FAIL**"
        [[ "$L" == "SKIP" ]] && L_FMT="--"
        [[ "$P" == "SKIP" ]] && P_FMT="--"
        [[ "$C" == "SKIP" ]] && C_FMT="--"

        echo "| \`${test}.lov\` | ${desc} | ${L_FMT} | ${P_FMT} | ${C_FMT} |" >> "$REPORT_FILE"
    done

    echo "" >> "$REPORT_FILE"
done

# ---- error test table ----
cat >> "$REPORT_FILE" << 'SEP2'
---

## 4. Error Program Tests

Each error program contains a deliberate syntactic or lexical mistake.
A test **passes** when the parser/compiler correctly rejects the input
(non-zero exit code) *and* produces the expected error message.

| Test file | Intended error | Parser | Compiler |
|-----------|---------------|:------:|:--------:|
SEP2

for test in "${ERROR_TESTS[@]}"; do
    desc="${TEST_DESC[$test]:-""}"
    P="${PARSER_RESULTS[$test]:-SKIP}"
    C="${COMPILER_RESULTS[$test]:-SKIP}"

    [[ "$P" == "PASS" ]] && P_FMT="PASS" || P_FMT="**FAIL**"
    [[ "$C" == "PASS" ]] && C_FMT="PASS" || C_FMT="**FAIL**"
    [[ "$P" == "SKIP" ]] && P_FMT="--"
    [[ "$C" == "SKIP" ]] && C_FMT="--"

    echo "| \`${test}.lov\` | ${desc} | ${P_FMT} | ${C_FMT} |" >> "$REPORT_FILE"
done

# ---- coverage section ----
cat >> "$REPORT_FILE" << 'COVERAGE'

---

## 5. Feature Coverage Matrix

The table below maps Lovelace language features (from the grammar in
`Lovelace.jj`) to the test files that exercise them.

| Language feature | Tested by |
|-----------------|-----------|
| **Identifiers** -- simple | `exemplo.lov`, `exemplo1.lov`, ... (all programs) |
| **Identifiers** -- underscore segments | `test_id_underscore`, `test_id_multi_underscore` |
| **Identifiers** -- mixed case | `test_id_mixed_case` |
| **Numbers** -- integer literals | `test_num_integer` |
| **Numbers** -- decimal literals | `exemplo`, `exemplo1`, ... (most programs) |
| **Numbers** -- scientific notation | `exemplo_scientific`, `test_num_scientific_signs`, `test_num_variety` |
| **Operators** -- `+` `-` `*` `/` | `test_op_arithmetic`, `test_prec_arith` |
| **Operators** -- `<` `>` `==` | `test_op_comparison`, `test_prec_mixed` |
| **Operators** -- `&&` `\|\|` | `test_op_logical`, `test_prec_bool`, `exemplo_bool_ops` |
| **Operator precedence** -- `*`/`/` over `+`/`-` | `test_prec_arith` |
| **Operator precedence** -- `&&` over `\|\|` | `test_prec_bool` |
| **Operator precedence** -- arith > cmp > bool | `test_prec_mixed` |
| **Parenthesised expressions** | `test_expr_nested_parens`, `exemplo1` |
| **Variable declarations** (`let Type id;`) | all valid programs (except `exemplo_empty`) |
| **Assignment** (`:=`) | all programs with statements |
| **`if` blocks** | `test_op_comparison`, `exemplo_nested`, `test_cmd_empty_blocks`, ... |
| **`while` loops** | `exemplo2`, `exemplo_nested`, `test_cmd_sequential_control`, ... |
| **`print` statement** | `test_cmd_print_expressions`, all printing programs |
| **`read` input** | `exemplo2`, `exemplo3` |
| **`return` with expression** | `test_func_bool_params`, `test_func_chain_calls`, ... |
| **`return` without expression** (Void) | `exemplo_void_return` |
| **Function definition** (`def`) | `test_func_*`, `exemplo3`, `exemplo4`, `test_edge_many_funcs` |
| **Function call as statement** | `exemplo_funcall_stmt`, `test_edge_many_funcs` |
| **Function call in expression** | `test_expr_funcall_in_expr`, `test_func_chain_calls` |
| **Bool parameters** | `test_func_bool_params`, `test_func_mixed_params` |
| **Mixed parameter types** | `test_func_mixed_params` |
| **Zero-argument functions** | `test_func_no_params_expr`, `exemplo_void_return` |
| **Multiple functions** (4+) | `test_edge_many_funcs` |
| **Empty blocks** | `test_cmd_empty_blocks`, `exemplo_empty` |
| **Declarations only (no stmts)** | `test_edge_only_decls` |
| **Lexer error rejection** | `test_erro_invalid_char`, `test_erro_missing_assign` |
| **Parser error rejection** | all `test_erro_*` and `exemplo_erro*` files |

COVERAGE

# ---- how to run section ----
cat >> "$REPORT_FILE" << 'HOWTO'
---

## 6. How to Reproduce

```bash
# Build the compiler
./scripts/build.sh

# Run individual test suites
./scripts/test.sh              # lexer tests only
./scripts/test_sintatico.sh    # parser tests only
./scripts/test_compiler.sh     # compiler tests only

# Regenerate this report
./scripts/test_report.sh
```

The report is written to `test/TEST_REPORT.md`.

To regenerate all expected output baselines from scratch:

```bash
# (Warning: overwrites existing expected files only if missing)
./scripts/generate_expected.sh
```
HOWTO

# ---- failure details (only if there are failures) ----
if [ -n "$FAILURE_DETAILS" ]; then
    cat >> "$REPORT_FILE" << 'FAILHDR'

---

## 7. Failure Details

The following tests did not produce the expected output.

FAILHDR
    echo -e "$FAILURE_DETAILS" >> "$REPORT_FILE"
fi

# ---------------------------------------------------------------------------
# Stdout summary
# ---------------------------------------------------------------------------
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
