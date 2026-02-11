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
# Auto-discover tests
# ---------------------------------------------------------------------------
source "${SCRIPT_DIR}/test_discover.sh"

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
    echo "**${TOTAL_FAIL} check(s) failed** -- see [Failure Details](#6-failure-details) below." >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" << 'SEP1'

---

## 3. Valid Program Tests

Each valid `.lov` program is run through all three phases. The table below
groups tests by the language feature they exercise.

SEP1

# ---- valid test tables, grouped by category ----
for cat_idx in $(seq 0 $((NUM_CATEGORIES - 1))); do
    # Skip empty categories
    arr_name="CAT_${cat_idx}[@]"
    arr_contents=("${!arr_name}")
    [ ${#arr_contents[@]} -eq 0 ] && continue

    cat_name="${CATEGORY_NAMES[$cat_idx]}"
    echo "### 3.$((cat_idx + 1)). ${cat_name}" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "| Test file | Description | Lexer | Parser | Compiler |" >> "$REPORT_FILE"
    echo "|-----------|-------------|:-----:|:------:|:--------:|" >> "$REPORT_FILE"

    for test in "${arr_contents[@]}"; do
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

# ---- how to run section ----
cat >> "$REPORT_FILE" << 'HOWTO'

---

## 5. How to Reproduce

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

## 6. Failure Details

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
