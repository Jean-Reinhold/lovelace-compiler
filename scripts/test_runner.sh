#!/bin/bash
# test_runner.sh -- Unified test runner for all Lovelace compiler phases.
#
# Usage:
#   ./scripts/test_runner.sh [lexer|parser|compiler|all] [OPTIONS]
#
# Options:
#   -f, --filter PATTERN   Only run tests whose name matches PATTERN
#   -v, --verbose          Show file contents on pass
#   --no-pager             Skip piping through less
#
# If no phase is given, defaults to "all".

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

cd "$PROJECT_ROOT"

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
PHASES=()
FILTER=""
VERBOSE=0
NO_PAGER=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        lexer|parser|compiler|all)
            PHASES+=("$1")
            shift
            ;;
        -f|--filter)
            FILTER="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        --no-pager)
            NO_PAGER=1
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            echo "Usage: $0 [lexer|parser|compiler|all] [-f PATTERN] [-v] [--no-pager]"
            exit 1
            ;;
    esac
done

export VERBOSE

# Default to all phases
if [ ${#PHASES[@]} -eq 0 ]; then
    PHASES=("all")
fi

# Expand "all" into individual phases
EXPANDED_PHASES=()
for p in "${PHASES[@]}"; do
    if [ "$p" = "all" ]; then
        EXPANDED_PHASES+=("lexer" "parser" "compiler")
    else
        EXPANDED_PHASES+=("$p")
    fi
done

# Deduplicate
PHASES=($(echo "${EXPANDED_PHASES[@]}" | tr ' ' '\n' | sort -u))

# ---------------------------------------------------------------------------
# Auto-build if classes are missing
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
# Source shared libraries
# ---------------------------------------------------------------------------
source "${SCRIPT_DIR}/test_discover.sh"

__FORCE_COLOR=1
source "${SCRIPT_DIR}/test_lib.sh"

# ---------------------------------------------------------------------------
# Apply filter
# ---------------------------------------------------------------------------
filter_tests() {
    local -n arr=$1
    if [ -z "$FILTER" ]; then
        return
    fi
    local filtered=()
    for t in "${arr[@]}"; do
        if [[ "$t" == *${FILTER}* ]]; then
            filtered+=("$t")
        fi
    done
    arr=("${filtered[@]}")
}

FILTERED_VALID=("${VALID_TESTS[@]}")
FILTERED_ERROR=("${ERROR_TESTS[@]}")
filter_tests FILTERED_VALID
filter_tests FILTERED_ERROR

# ---------------------------------------------------------------------------
# Phase: Lexer
# ---------------------------------------------------------------------------
run_lexer_tests() {
    local PASSED=0
    local FAILED=0

    start_timer
    print_suite_header "Lovelace Lexical Analyzer Tests"
    init_progress ${#FILTERED_VALID[@]}

    for test in "${FILTERED_VALID[@]}"; do
        local INPUT_FILE="test/examples/${test}.lov"
        local EXPECTED_FILE="test/expected/${test}.out"
        local ACTUAL_FILE="/tmp/${test}_actual.out"
        local desc="${TEST_DESC[$test]:-$test}"

        advance_progress

        if [ ! -f "$INPUT_FILE" ]; then
            print_fail "$test" "$desc" "input file not found"
            FAILED=$((FAILED + 1))
            continue
        fi

        if [ ! -f "$EXPECTED_FILE" ]; then
            mkdir -p test/expected
            java lovelace.Lovelace "$INPUT_FILE" > "$EXPECTED_FILE" 2>&1
            print_pass "$test" "$desc (baseline created)"
            PASSED=$((PASSED + 1))
            verbose_file "Input" "$INPUT_FILE"
            verbose_file "Output (baseline)" "$EXPECTED_FILE"
            continue
        fi

        java lovelace.Lovelace "$INPUT_FILE" > "$ACTUAL_FILE" 2>&1

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
    done

    print_summary $PASSED $FAILED
    print_timing

    # Export results for grand summary
    LEXER_PASSED=$PASSED
    LEXER_FAILED=$FAILED
}

# ---------------------------------------------------------------------------
# Phase: Parser
# ---------------------------------------------------------------------------
run_parser_tests() {
    local PASSED=0
    local FAILED=0
    local TOTAL=$((${#FILTERED_VALID[@]} + ${#FILTERED_ERROR[@]}))

    start_timer
    print_suite_header "Lovelace Syntax Analyzer Tests"
    init_progress "$TOTAL"

    print_section_header "Valid Programs (${#FILTERED_VALID[@]})"

    for test in "${FILTERED_VALID[@]}"; do
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

    print_section_header "Error Programs (${#FILTERED_ERROR[@]})"

    for test in "${FILTERED_ERROR[@]}"; do
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
    print_timing

    PARSER_PASSED=$PASSED
    PARSER_FAILED=$FAILED
}

# ---------------------------------------------------------------------------
# Phase: Compiler
# ---------------------------------------------------------------------------
run_compiler_tests() {
    local PASSED=0
    local FAILED=0
    local TOTAL=$((${#FILTERED_VALID[@]} + ${#FILTERED_ERROR[@]}))

    start_timer
    print_suite_header "Lovelace Compiler Tests"
    init_progress "$TOTAL"

    print_section_header "Valid Programs (${#FILTERED_VALID[@]})"

    for test in "${FILTERED_VALID[@]}"; do
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

        rm -f "$GENERATED_FILE"
    done

    print_section_header "Error Programs (${#FILTERED_ERROR[@]})"

    for test in "${FILTERED_ERROR[@]}"; do
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

        rm -f "test/examples/${test}.c"
    done

    print_summary $PASSED $FAILED
    print_timing

    COMPILER_PASSED=$PASSED
    COMPILER_FAILED=$FAILED
}

# ---------------------------------------------------------------------------
# Main: run selected phases
# ---------------------------------------------------------------------------
LEXER_PASSED=0;  LEXER_FAILED=0
PARSER_PASSED=0; PARSER_FAILED=0
COMPILER_PASSED=0; COMPILER_FAILED=0

run_all() {
    local ANY_FAIL=0
    local SUMMARIES=()

    for phase in "${PHASES[@]}"; do
        case "$phase" in
            lexer)
                run_lexer_tests
                SUMMARIES+=("Lexer:${LEXER_PASSED}:${LEXER_FAILED}")
                [ $LEXER_FAILED -gt 0 ] && ANY_FAIL=1
                ;;
            parser)
                run_parser_tests
                SUMMARIES+=("Parser:${PARSER_PASSED}:${PARSER_FAILED}")
                [ $PARSER_FAILED -gt 0 ] && ANY_FAIL=1
                ;;
            compiler)
                run_compiler_tests
                SUMMARIES+=("Compiler:${COMPILER_PASSED}:${COMPILER_FAILED}")
                [ $COMPILER_FAILED -gt 0 ] && ANY_FAIL=1
                ;;
        esac
    done

    # Print grand summary if more than one phase was run
    if [ ${#SUMMARIES[@]} -gt 1 ]; then
        print_grand_summary "${SUMMARIES[@]}"
    fi

    return $ANY_FAIL
}

if [ "$NO_PAGER" -eq 1 ] || [ ! -t 1 ]; then
    run_all
    exit $?
else
    run_all 2>&1 | less -R
    exit ${PIPESTATUS[0]}
fi
