# Lovelace Compiler -- Test Report

> Generated on **2026-02-11 10:04:26** from branch `main` at commit [`5eede91`](../../commit/5eede913e5ad051b29a25714d635f3ac5c43f19a).

---

## 1. Overview

This report summarises the results of the automated test suite for the
**Lovelace compiler**, covering three compilation phases:

| Phase | Tool | What is verified |
|-------|------|------------------|
| **Lexer** | `lovelace.Lovelace` | Tokenisation -- every token is correctly classified (reserved word, identifier, number, operator, punctuation). |
| **Parser** | `lovelace.LovelaceSintatico` | Syntax analysis -- the token stream is accepted (valid programs) or rejected with the expected error message (error programs). |
| **Compiler** | `lovelace.LovelaceCompiler` | Code generation -- the produced C source matches the expected reference file byte-for-byte (valid programs) or the compiler exits with a non-zero status (error programs). |

The suite contains **51 test programs**: 36 valid programs and 15 programs that must be rejected.

---

## 2. Result Summary

| Phase | Passed | Failed | Total |
|------:|-------:|-------:|------:|
| Lexer | 36 | 0 | 36 |
| Parser | 51 | 0 | 51 |
| Compiler | 51 | 0 | 51 |
| **Total** | **138** | **0** | **138** |

**All 138 checks passed.**

---

## 3. Valid Program Tests

Each valid `.lov` program is run through all three phases. The table below
groups tests by the language feature they exercise.

### 3.1. Original Examples

| Test file | Description | Lexer | Parser | Compiler |
|-----------|-------------|:-----:|:------:|:--------:|
| `exemplo.lov` | Variable declaration, assignment and print | PASS | PASS | PASS |
| `exemplo1.lov` | Conditionals, boolean assignment, arithmetic with parentheses | PASS | PASS | PASS |
| `exemplo2.lov` | Functions, loops, read input, nested control flow | PASS | PASS | PASS |
| `exemplo3.lov` | Multiple functions (soma, fatorial, ehPositivo), function calls in expressions | PASS | PASS | PASS |
| `exemplo4.lov` | Void functions, multi-parameter functions, nested ifs | PASS | PASS | PASS |
| `exemplo_empty.lov` | Empty main body (no declarations, no statements) | PASS | PASS | PASS |
| `exemplo_nested.lov` | Deeply nested if/while statements | PASS | PASS | PASS |
| `exemplo_funcall_stmt.lov` | Function call used as a standalone statement | PASS | PASS | PASS |
| `exemplo_bool_ops.lov` | Boolean variables with && and || operators | PASS | PASS | PASS |
| `exemplo_scientific.lov` | Scientific notation literals (1.5E10, 2.0e3) | PASS | PASS | PASS |
| `exemplo_multiparams.lov` | Function with four Float parameters | PASS | PASS | PASS |
| `exemplo_void_return.lov` | Void function with bare return statement | PASS | PASS | PASS |

### 3.2. Identifiers

| Test file | Description | Lexer | Parser | Compiler |
|-----------|-------------|:-----:|:------:|:--------:|
| `test_id_underscore.lov` | Identifiers with single underscore (my_var, x_1) | PASS | PASS | PASS |
| `test_id_multi_underscore.lov` | Multi-segment underscore identifiers (a_b_c, long_variable_name_1) | PASS | PASS | PASS |
| `test_id_mixed_case.lov` | CamelCase identifiers mixing Float and Bool variables | PASS | PASS | PASS |

### 3.3. Number Formats

| Test file | Description | Lexer | Parser | Compiler |
|-----------|-------------|:-----:|:------:|:--------:|
| `test_num_integer.lov` | Plain integer literals (5, 100, 0) | PASS | PASS | PASS |
| `test_num_scientific_signs.lov` | Scientific notation with explicit +/- signs (1.0E+5, 2.5E-3) | PASS | PASS | PASS |
| `test_num_variety.lov` | All number formats combined: integer, decimal, scientific, signed exponent | PASS | PASS | PASS |

### 3.4. Operators

| Test file | Description | Lexer | Parser | Compiler |
|-----------|-------------|:-----:|:------:|:--------:|
| `test_op_arithmetic.lov` | Each arithmetic operator isolated: +, -, *, / | PASS | PASS | PASS |
| `test_op_comparison.lov` | Each comparison operator isolated: <, >, == | PASS | PASS | PASS |
| `test_op_logical.lov` | Logical && and || with all boolean input combinations | PASS | PASS | PASS |

### 3.5. Operator Precedence

| Test file | Description | Lexer | Parser | Compiler |
|-----------|-------------|:-----:|:------:|:--------:|
| `test_prec_arith.lov` | Arithmetic precedence: * and / bind tighter than + and - | PASS | PASS | PASS |
| `test_prec_bool.lov` | Boolean precedence: && binds tighter than || | PASS | PASS | PASS |
| `test_prec_mixed.lov` | Full precedence chain: arithmetic > comparison > logical | PASS | PASS | PASS |

### 3.6. Expressions

| Test file | Description | Lexer | Parser | Compiler |
|-----------|-------------|:-----:|:------:|:--------:|
| `test_expr_nested_parens.lov` | Deeply nested parenthesized arithmetic expressions | PASS | PASS | PASS |
| `test_expr_funcall_in_expr.lov` | Function calls inside arithmetic expressions and as nested arguments | PASS | PASS | PASS |
| `test_expr_bool_literals_in_expr.lov` | Boolean literals (true/false) in conditions, comparisons, and print | PASS | PASS | PASS |

### 3.7. Commands

| Test file | Description | Lexer | Parser | Compiler |
|-----------|-------------|:-----:|:------:|:--------:|
| `test_cmd_empty_blocks.lov` | Empty if and while bodies (zero statements) | PASS | PASS | PASS |
| `test_cmd_sequential_control.lov` | Multiple sequential if and while blocks in the same scope | PASS | PASS | PASS |
| `test_cmd_print_expressions.lov` | Print with literal, variable, arithmetic, comparison, and Bool values | PASS | PASS | PASS |

### 3.8. Functions

| Test file | Description | Lexer | Parser | Compiler |
|-----------|-------------|:-----:|:------:|:--------:|
| `test_func_bool_params.lov` | Function with Bool parameter and Bool return type | PASS | PASS | PASS |
| `test_func_mixed_params.lov` | Function with mixed Float and Bool parameter types | PASS | PASS | PASS |
| `test_func_chain_calls.lov` | Functions calling other user-defined functions (chaining) | PASS | PASS | PASS |
| `test_func_no_params_expr.lov` | Zero-argument functions used inside expressions | PASS | PASS | PASS |

### 3.9. Edge Cases

| Test file | Description | Lexer | Parser | Compiler |
|-----------|-------------|:-----:|:------:|:--------:|
| `test_edge_only_decls.lov` | Declarations only, no executable statements in main | PASS | PASS | PASS |
| `test_edge_many_funcs.lov` | Four+ function definitions with forward declarations | PASS | PASS | PASS |

---

## 4. Error Program Tests

Each error program contains a deliberate syntactic or lexical mistake.
A test **passes** when the parser/compiler correctly rejects the input
(non-zero exit code) *and* produces the expected error message.

| Test file | Intended error | Parser | Compiler |
|-----------|---------------|:------:|:--------:|
| `exemplo_erro.lov` | Missing semicolon after assignment | PASS | PASS |
| `exemplo_erro2.lov` | Missing closing end keyword | PASS | PASS |
| `exemplo_erro3.lov` | Invalid expression (* without left operand) | PASS | PASS |
| `exemplo_erro4.lov` | Missing begin keyword in main | PASS | PASS |
| `test_erro_invalid_char.lov` | Invalid character @ in source (lexer error) | PASS | PASS |
| `test_erro_missing_rparen.lov` | Missing ) in if condition | PASS | PASS |
| `test_erro_missing_end_semi.lov` | Missing ; after end in if block | PASS | PASS |
| `test_erro_missing_assign.lov` | Using = instead of := for assignment | PASS | PASS |
| `test_erro_keyword_as_id.lov` | Reserved word (begin) used as variable name | PASS | PASS |
| `test_erro_def_no_type.lov` | Function definition without return type | PASS | PASS |
| `test_erro_empty_parens_expr.lov` | Empty parentheses () used as expression | PASS | PASS |
| `test_erro_double_semi.lov` | Bare semicolon in statement position | PASS | PASS |
| `test_erro_missing_lparen_if.lov` | if without parenthesized condition | PASS | PASS |
| `test_erro_missing_main.lov` | Program with no main function | PASS | PASS |
| `test_erro_func_after_main.lov` | Function definition inside main body (wrong scope) | PASS | PASS |

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
