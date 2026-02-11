#!/bin/bash
# test_discover.sh -- Auto-discover, classify, categorize and describe .lov tests.
# Source this file (do NOT execute it).  It expects PROJECT_ROOT to be set.

if [ -z "$PROJECT_ROOT" ]; then
    echo "ERROR: PROJECT_ROOT must be set before sourcing test_discover.sh" >&2
    return 1 2>/dev/null || exit 1
fi

# ---------------------------------------------------------------------------
# 1. Auto-discover all .lov files (sorted)
# ---------------------------------------------------------------------------
ALL_TESTS=()
for f in $(ls "$PROJECT_ROOT/test/examples/"*.lov 2>/dev/null | sort); do
    ALL_TESTS+=("$(basename "$f" .lov)")
done

# ---------------------------------------------------------------------------
# 2. Auto-classify: filenames containing "erro" -> error, rest -> valid
# ---------------------------------------------------------------------------
VALID_TESTS=()
ERROR_TESTS=()
for t in "${ALL_TESTS[@]}"; do
    if [[ "$t" == *erro* ]]; then
        ERROR_TESTS+=("$t")
    else
        VALID_TESTS+=("$t")
    fi
done

# ---------------------------------------------------------------------------
# 3. Auto-extract descriptions from the first line of each .lov file
# ---------------------------------------------------------------------------
declare -A TEST_DESC
for t in "${ALL_TESTS[@]}"; do
    first_line=$(head -1 "$PROJECT_ROOT/test/examples/${t}.lov")
    if [[ "$first_line" == //* ]]; then
        # Strip leading "// "
        desc="${first_line#// }"
        # Also handle "//..." without space
        desc="${desc#//}"
        TEST_DESC[$t]="$desc"
    else
        # Fallback: humanize filename
        TEST_DESC[$t]="${t//_/ }"
    fi
done

# ---------------------------------------------------------------------------
# 4. Auto-categorize valid tests by prefix
# ---------------------------------------------------------------------------
declare -a CATEGORY_PREFIXES=("exemplo" "test_id_" "test_num_" "test_op_" "test_prec_" "test_expr_" "test_cmd_" "test_func_" "test_edge_")
declare -a CATEGORY_NAMES=("Original Examples" "Identifiers" "Number Formats" "Operators" "Operator Precedence" "Expressions" "Commands" "Functions" "Edge Cases")

# Build CAT_0..CAT_N arrays dynamically
NUM_CATEGORIES=${#CATEGORY_PREFIXES[@]}

# Clear any previous CAT_ arrays
for i in $(seq 0 $((NUM_CATEGORIES - 1))); do
    eval "CAT_${i}=()"
done

for t in "${VALID_TESTS[@]}"; do
    matched=false
    for i in $(seq 1 $((NUM_CATEGORIES - 1))); do
        prefix="${CATEGORY_PREFIXES[$i]}"
        if [[ "$t" == ${prefix}* ]]; then
            eval "CAT_${i}+=(\"$t\")"
            matched=true
            break
        fi
    done
    if ! $matched; then
        # Fallback to category 0 (Original Examples / exemplo)
        eval "CAT_0+=(\"$t\")"
    fi
done
