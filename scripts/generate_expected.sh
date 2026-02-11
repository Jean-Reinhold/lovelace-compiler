#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

cd "$PROJECT_ROOT"

echo "Generating expected test outputs..."
echo "=========================================="
echo ""

# Build first
if [ ! -d "lovelace" ] || [ ! -f "lovelace/Lovelace.class" ]; then
    echo "Building project first..."
    bash scripts/build.sh
    if [ $? -ne 0 ]; then
        echo "Error: Build failed."
        exit 1
    fi
    echo ""
fi

mkdir -p test/expected
mkdir -p test/expected_sintatico
mkdir -p test/expected_compiler

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

GENERATED=0
SKIPPED=0

echo "--- Generating valid test expected outputs ---"
echo ""

for test in "${VALID_TESTS[@]}"; do
    INPUT_FILE="test/examples/${test}.lov"

    if [ ! -f "$INPUT_FILE" ]; then
        echo "  WARNING: Input file not found: $INPUT_FILE"
        continue
    fi

    # Lexer expected output
    LEXER_FILE="test/expected/${test}.out"
    if [ ! -f "$LEXER_FILE" ]; then
        java lovelace.Lovelace "$INPUT_FILE" > "$LEXER_FILE" 2>&1
        echo "  Created: $LEXER_FILE"
        GENERATED=$((GENERATED + 1))
    else
        SKIPPED=$((SKIPPED + 1))
    fi

    # Parser expected output
    PARSER_FILE="test/expected_sintatico/${test}.out"
    if [ ! -f "$PARSER_FILE" ]; then
        java lovelace.LovelaceSintatico "$INPUT_FILE" > "$PARSER_FILE" 2>&1
        echo "  Created: $PARSER_FILE"
        GENERATED=$((GENERATED + 1))
    else
        SKIPPED=$((SKIPPED + 1))
    fi

    # Compiler expected output
    COMPILER_FILE="test/expected_compiler/${test}.c"
    if [ ! -f "$COMPILER_FILE" ]; then
        java lovelace.LovelaceCompiler "$INPUT_FILE" > /dev/null 2>&1
        GENERATED_C="test/examples/${test}.c"
        if [ -f "$GENERATED_C" ]; then
            cp "$GENERATED_C" "$COMPILER_FILE"
            rm -f "$GENERATED_C"
            echo "  Created: $COMPILER_FILE"
            GENERATED=$((GENERATED + 1))
        else
            echo "  WARNING: Compiler did not generate C file for $test"
        fi
    else
        SKIPPED=$((SKIPPED + 1))
    fi
done

echo ""
echo "--- Generating error test expected outputs ---"
echo ""

for test in "${ERROR_TESTS[@]}"; do
    INPUT_FILE="test/examples/${test}.lov"

    if [ ! -f "$INPUT_FILE" ]; then
        echo "  WARNING: Input file not found: $INPUT_FILE"
        continue
    fi

    # Parser expected output (error message)
    PARSER_FILE="test/expected_sintatico/${test}.out"
    if [ ! -f "$PARSER_FILE" ]; then
        java lovelace.LovelaceSintatico "$INPUT_FILE" > "$PARSER_FILE" 2>&1
        echo "  Created: $PARSER_FILE"
        GENERATED=$((GENERATED + 1))
    else
        SKIPPED=$((SKIPPED + 1))
    fi

    # Clean up any accidentally generated .c files
    rm -f "test/examples/${test}.c"
done

echo ""
echo "=========================================="
echo "Generated: $GENERATED files"
echo "Skipped (already exist): $SKIPPED files"
echo "Done!"
