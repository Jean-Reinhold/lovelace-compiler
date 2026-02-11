#!/bin/bash
# test_lib.sh -- Shared formatting library for Lovelace test scripts.
# Source this file (do NOT execute it).
# Set __FORCE_COLOR=1 before sourcing to enable colors even when stdout is not a TTY.

# ---------------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------------
if [[ "${__FORCE_COLOR:-0}" == "1" ]] || [[ -t 1 ]]; then
    C_GREEN=$'\033[32m'
    C_RED=$'\033[31m'
    C_YELLOW=$'\033[33m'
    C_BOLD=$'\033[1m'
    C_DIM=$'\033[2m'
    C_RESET=$'\033[0m'
else
    C_GREEN=""
    C_RED=""
    C_YELLOW=""
    C_BOLD=""
    C_DIM=""
    C_RESET=""
fi

# ---------------------------------------------------------------------------
# Progress counter
# ---------------------------------------------------------------------------
_PROGRESS_CURRENT=0
_PROGRESS_TOTAL=0

init_progress() {
    _PROGRESS_CURRENT=0
    _PROGRESS_TOTAL=$1
}

advance_progress() {
    _PROGRESS_CURRENT=$((_PROGRESS_CURRENT + 1))
}

# Returns e.g. "[ 3/51]"
progress_tag() {
    local width=${#_PROGRESS_TOTAL}
    printf "[%${width}d/%d]" "$_PROGRESS_CURRENT" "$_PROGRESS_TOTAL"
}

# ---------------------------------------------------------------------------
# Result printers
# ---------------------------------------------------------------------------
print_pass() {
    local test_name="$1"
    local desc="$2"
    printf "%s ${C_GREEN}PASS${C_RESET}  %s -- %s\n" "$(progress_tag)" "$test_name.lov" "$desc"
}

print_fail() {
    local test_name="$1"
    local desc="$2"
    local reason="$3"
    printf "%s ${C_RED}FAIL${C_RESET}  %s -- %s\n" "$(progress_tag)" "$test_name.lov" "$desc"
    if [[ -n "$reason" ]]; then
        printf "         ${C_DIM}Reason: %s${C_RESET}\n" "$reason"
    fi
}

print_skip() {
    local test_name="$1"
    local desc="$2"
    local reason="$3"
    printf "%s ${C_YELLOW}SKIP${C_RESET}  %s -- %s\n" "$(progress_tag)" "$test_name.lov" "$desc"
    if [[ -n "$reason" ]]; then
        printf "         ${C_DIM}Reason: %s${C_RESET}\n" "$reason"
    fi
}

# ---------------------------------------------------------------------------
# print_file_excerpt LABEL FILE_PATH [MAX_LINES]
# Always shown (not gated by VERBOSE). Dimmed, indented, capped.
# ---------------------------------------------------------------------------
print_file_excerpt() {
    local label="$1"
    local file_path="$2"
    local max_lines="${3:-20}"

    printf "\n         ${C_DIM}── %s ──${C_RESET}\n" "$label"
    if [[ ! -f "$file_path" ]]; then
        printf "         ${C_DIM}(file not found)${C_RESET}\n"
        return
    fi
    local total_lines
    total_lines=$(wc -l < "$file_path" | tr -d ' ')
    cat -n "$file_path" | head -n "$max_lines" | sed 's/^/         /'
    if (( total_lines > max_lines )); then
        local remaining=$((total_lines - max_lines))
        printf "         ${C_DIM}... (%d more lines)${C_RESET}\n" "$remaining"
    fi
}

# ---------------------------------------------------------------------------
# colored_diff FILE_A FILE_B
# ---------------------------------------------------------------------------
colored_diff() {
    local file_a="$1"
    local file_b="$2"
    local max_lines=30
    local diff_output

    if command -v git &>/dev/null; then
        diff_output=$(git diff --no-index --color=always -- "$file_a" "$file_b" 2>/dev/null)
    else
        diff_output=$(diff -u "$file_a" "$file_b" 2>/dev/null)
    fi

    if [[ -z "$diff_output" ]]; then
        return
    fi

    echo ""
    local total_lines
    total_lines=$(printf '%s\n' "$diff_output" | wc -l | tr -d ' ')
    printf '%s\n' "$diff_output" | head -n "$max_lines" | sed 's/^/    /'
    if (( total_lines > max_lines )); then
        local remaining=$((total_lines - max_lines))
        printf "    ${C_DIM}... (%d more lines)${C_RESET}\n" "$remaining"
    fi
    echo ""
}

# ---------------------------------------------------------------------------
# verbose_file LABEL FILE_PATH
# Shows file contents with line numbers, only when VERBOSE=1
# ---------------------------------------------------------------------------
verbose_file() {
    local label="$1"
    local file_path="$2"
    if [[ "${VERBOSE:-0}" != "1" ]]; then
        return
    fi
    printf "\n         ${C_DIM}── %s ──${C_RESET}\n" "$label"
    if [[ -f "$file_path" ]]; then
        cat -n "$file_path" | sed 's/^/         /'
    else
        printf "         ${C_DIM}(file not found)${C_RESET}\n"
    fi
}

# ---------------------------------------------------------------------------
# Headers and summary
# ---------------------------------------------------------------------------
print_suite_header() {
    local title="$1"
    echo "${C_BOLD}${title}${C_RESET}"
    echo "=================================================="
    echo ""
}

print_section_header() {
    local title="$1"
    echo ""
    echo "${C_BOLD}${title}${C_RESET}"
    echo "--------------------------------------------------"
    echo ""
}

print_summary() {
    local passed=$1
    local failed=$2
    local total=$((passed + failed))

    echo ""
    echo "=================================================="
    echo "${C_BOLD}Results:${C_RESET}"
    printf "  Passed: ${C_GREEN}%d${C_RESET}\n" "$passed"
    if (( failed > 0 )); then
        printf "  Failed: ${C_RED}%d${C_RESET}\n" "$failed"
    else
        printf "  Failed: %d\n" "$failed"
    fi
    printf "  Total:  %d\n" "$total"
    echo ""

    if (( failed == 0 )); then
        echo "${C_GREEN}All ${total} tests passed.${C_RESET}"
    else
        echo "${C_RED}${failed} of ${total} tests failed.${C_RESET}"
    fi
}

# ---------------------------------------------------------------------------
# Dimmed/yellow warning printer (for gcc, etc.)
# ---------------------------------------------------------------------------
print_warning() {
    local msg="$1"
    printf "         ${C_YELLOW}${C_DIM}%s${C_RESET}\n" "$msg"
}
