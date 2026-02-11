#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

cd "$PROJECT_ROOT"

# Parse flags
VERBOSE=0
for arg in "$@"; do
    case "$arg" in
        -v|--verbose) VERBOSE=1 ;;
    esac
done
export VERBOSE

if [ ! -d "lovelace" ] || [ ! -f "lovelace/LovelaceSintatico.class" ]; then
    echo "Error: Parser not compiled. Please run ./scripts/build.sh first."
    exit 1
fi

source "${SCRIPT_DIR}/test_discover.sh"

__FORCE_COLOR=1
source "${SCRIPT_DIR}/test_lib.sh"

run_tests() {
    local PASSED=0
    local FAILED=0
    local TOTAL=$((${#VALID_TESTS[@]} + ${#ERROR_TESTS[@]}))

    print_suite_header "Lovelace Syntax Analyzer Tests"
    init_progress "$TOTAL"

    print_section_header "Valid Programs (${#VALID_TESTS[@]})"

    for test in "${VALID_TESTS[@]}"; do
        local INPUT_FILE="test/examples/${test}.lov"
        local EXPECTED_FILE="test/expected_sintatico/${test}.out"
        local ACTUAL_FILE="/tmp/${test}_sintatico_actual.out"
        local desc="${TEST_DESC[$test]:-$test}"

        advance_progress

        if [ ! -f "$INPUT_FILE" ]; then
            print_fail "$test" "$desc" "input file not found"
            FAILED=$((FAILED + 1))
            continue
        fi

        java lovelace.LovelaceSintatico "$INPUT_FILE" > "$ACTUAL_FILE" 2>&1
        local EXIT_CODE=$?

        if [ ! -f "$EXPECTED_FILE" ]; then
            mkdir -p test/expected_sintatico
            cp "$ACTUAL_FILE" "$EXPECTED_FILE"
            print_pass "$test" "$desc (baseline created)"
            PASSED=$((PASSED + 1))
            verbose_file "Input" "$INPUT_FILE"
            verbose_file "Output (baseline)" "$ACTUAL_FILE"
            continue
        fi

        if [ $EXIT_CODE -eq 0 ]; then
            if grep -q "Análise sintática concluída com sucesso!" "$ACTUAL_FILE"; then
                if diff -q "$EXPECTED_FILE" "$ACTUAL_FILE" > /dev/null 2>&1; then
                    print_pass "$test" "$desc"
                    PASSED=$((PASSED + 1))
                    verbose_file "Input" "$INPUT_FILE"
                    verbose_file "Expected" "$EXPECTED_FILE"
                    verbose_file "Actual" "$ACTUAL_FILE"
                else
                    print_fail "$test" "$desc" "output mismatch"
                    print_file_excerpt "Input ($INPUT_FILE)" "$INPUT_FILE"
                    colored_diff "$EXPECTED_FILE" "$ACTUAL_FILE"
                    FAILED=$((FAILED + 1))
                fi
            else
                print_fail "$test" "$desc" "no success message in output"
                print_file_excerpt "Input ($INPUT_FILE)" "$INPUT_FILE"
                FAILED=$((FAILED + 1))
            fi
        else
            print_fail "$test" "$desc" "parser returned error for valid program"
            print_file_excerpt "Input ($INPUT_FILE)" "$INPUT_FILE"
            FAILED=$((FAILED + 1))
        fi
    done

    print_section_header "Error Programs (${#ERROR_TESTS[@]})"

    for test in "${ERROR_TESTS[@]}"; do
        local INPUT_FILE="test/examples/${test}.lov"
        local EXPECTED_FILE="test/expected_sintatico/${test}.out"
        local ACTUAL_FILE="/tmp/${test}_sintatico_actual.out"
        local desc="${TEST_DESC[$test]:-$test}"

        advance_progress

        if [ ! -f "$INPUT_FILE" ]; then
            print_fail "$test" "$desc" "input file not found"
            FAILED=$((FAILED + 1))
            continue
        fi

        java lovelace.LovelaceSintatico "$INPUT_FILE" > "$ACTUAL_FILE" 2>&1
        local EXIT_CODE=$?

        if [ $EXIT_CODE -ne 0 ]; then
            if [ ! -f "$EXPECTED_FILE" ]; then
                mkdir -p test/expected_sintatico
                cp "$ACTUAL_FILE" "$EXPECTED_FILE"
                print_pass "$test" "$desc (baseline created)"
                PASSED=$((PASSED + 1))
                verbose_file "Input" "$INPUT_FILE"
                verbose_file "Output (baseline)" "$ACTUAL_FILE"
            else
                if diff -q "$EXPECTED_FILE" "$ACTUAL_FILE" > /dev/null 2>&1; then
                    print_pass "$test" "$desc"
                    PASSED=$((PASSED + 1))
                    verbose_file "Input" "$INPUT_FILE"
                    verbose_file "Expected" "$EXPECTED_FILE"
                    verbose_file "Actual" "$ACTUAL_FILE"
                else
                    print_fail "$test" "$desc" "error message mismatch"
                    print_file_excerpt "Input ($INPUT_FILE)" "$INPUT_FILE"
                    colored_diff "$EXPECTED_FILE" "$ACTUAL_FILE"
                    FAILED=$((FAILED + 1))
                fi
            fi
        else
            print_fail "$test" "$desc" "should have reported an error"
            print_file_excerpt "Input ($INPUT_FILE)" "$INPUT_FILE"
            FAILED=$((FAILED + 1))
        fi
    done

    print_summary $PASSED $FAILED

    if [ $FAILED -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

if [ -t 1 ]; then
    run_tests 2>&1 | less -R
    exit ${PIPESTATUS[0]}
else
    run_tests
fi
