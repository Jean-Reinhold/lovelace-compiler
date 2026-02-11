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

if [ ! -d "lovelace" ] || [ ! -f "lovelace/LovelaceCompiler.class" ]; then
    echo "Error: Compiler not compiled. Please run ./scripts/build.sh first."
    exit 1
fi

source "${SCRIPT_DIR}/test_discover.sh"

__FORCE_COLOR=1
source "${SCRIPT_DIR}/test_lib.sh"

run_tests() {
    local PASSED=0
    local FAILED=0
    local TOTAL=$((${#VALID_TESTS[@]} + ${#ERROR_TESTS[@]}))

    print_suite_header "Lovelace Compiler Tests"
    init_progress "$TOTAL"

    print_section_header "Valid Programs (${#VALID_TESTS[@]})"

    for test in "${VALID_TESTS[@]}"; do
        local INPUT_FILE="test/examples/${test}.lov"
        local EXPECTED_FILE="test/expected_compiler/${test}.c"
        local GENERATED_FILE="test/examples/${test}.c"
        local desc="${TEST_DESC[$test]:-$test}"

        advance_progress

        if [ ! -f "$INPUT_FILE" ]; then
            print_fail "$test" "$desc" "input file not found"
            FAILED=$((FAILED + 1))
            continue
        fi

        # Run compiler
        local OUTPUT
        OUTPUT=$(java lovelace.LovelaceCompiler "$INPUT_FILE" 2>&1)
        local EXIT_CODE=$?

        if [ $EXIT_CODE -ne 0 ]; then
            print_fail "$test" "$desc" "compiler error"
            print_file_excerpt "Input ($INPUT_FILE)" "$INPUT_FILE"
            if [[ -n "$OUTPUT" ]]; then
                printf "\n         ${C_DIM}── Compiler output ──${C_RESET}\n"
                printf '%s\n' "$OUTPUT" | sed 's/^/         /'
            fi
            FAILED=$((FAILED + 1))
            continue
        fi

        if [ ! -f "$GENERATED_FILE" ]; then
            print_fail "$test" "$desc" "no .c file generated"
            print_file_excerpt "Input ($INPUT_FILE)" "$INPUT_FILE"
            FAILED=$((FAILED + 1))
            continue
        fi

        # Compare with expected output
        if [ ! -f "$EXPECTED_FILE" ]; then
            mkdir -p test/expected_compiler
            cp "$GENERATED_FILE" "$EXPECTED_FILE"
            print_pass "$test" "$desc (baseline created)"
            PASSED=$((PASSED + 1))
            verbose_file "Input" "$INPUT_FILE"
            verbose_file "Generated C (baseline)" "$GENERATED_FILE"
        else
            if diff -q "$EXPECTED_FILE" "$GENERATED_FILE" > /dev/null 2>&1; then
                print_pass "$test" "$desc"
                PASSED=$((PASSED + 1))
                verbose_file "Input" "$INPUT_FILE"
                verbose_file "Expected C" "$EXPECTED_FILE"
                verbose_file "Generated C" "$GENERATED_FILE"
            else
                print_fail "$test" "$desc" "output mismatch"
                print_file_excerpt "Input ($INPUT_FILE)" "$INPUT_FILE"
                colored_diff "$EXPECTED_FILE" "$GENERATED_FILE"
                FAILED=$((FAILED + 1))
            fi
        fi

        # Verify generated C compiles with gcc (if available)
        if command -v gcc &> /dev/null; then
            local GCC_OUTPUT
            GCC_OUTPUT=$(gcc -fsyntax-only -Wno-format "$GENERATED_FILE" 2>&1)
            if [ $? -ne 0 ]; then
                print_warning "gcc: generated C has syntax errors:"
                while IFS= read -r line; do
                    print_warning "  $line"
                done <<< "$GCC_OUTPUT"
            fi
        fi

        # Clean up generated file
        rm -f "$GENERATED_FILE"
    done

    print_section_header "Error Programs (${#ERROR_TESTS[@]})"

    for test in "${ERROR_TESTS[@]}"; do
        local INPUT_FILE="test/examples/${test}.lov"
        local desc="${TEST_DESC[$test]:-$test}"

        advance_progress

        if [ ! -f "$INPUT_FILE" ]; then
            print_fail "$test" "$desc" "input file not found"
            FAILED=$((FAILED + 1))
            continue
        fi

        local OUTPUT
        OUTPUT=$(java lovelace.LovelaceCompiler "$INPUT_FILE" 2>&1)
        local EXIT_CODE=$?

        if [ $EXIT_CODE -ne 0 ]; then
            print_pass "$test" "$desc"
            PASSED=$((PASSED + 1))
            verbose_file "Input" "$INPUT_FILE"
        else
            print_fail "$test" "$desc" "should have reported an error"
            print_file_excerpt "Input ($INPUT_FILE)" "$INPUT_FILE"
            FAILED=$((FAILED + 1))
        fi

        # Clean up any accidentally generated file
        rm -f "test/examples/${test}.c"
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
