# Lovelace Compiler - Test Report

**Date:** 2026-02-11 09:53:43
**Branch:** main
**Commit:** 4f6808b

## Summary

| Phase | Passed | Failed | Total |
|-------|--------|--------|-------|
| Lexer | 36 | 0 | 36 |
| Parser | 51 | 0 | 51 |
| Compiler | 51 | 0 | 51 |
| **Total** | **138** | **0** | **138** |

## Valid Program Tests

| Test | Lexer | Parser | Compiler |
|------|-------|--------|----------|
| exemplo | PASS | PASS | PASS |
| exemplo1 | PASS | PASS | PASS |
| exemplo2 | PASS | PASS | PASS |
| exemplo3 | PASS | PASS | PASS |
| exemplo4 | PASS | PASS | PASS |
| exemplo_empty | PASS | PASS | PASS |
| exemplo_nested | PASS | PASS | PASS |
| exemplo_funcall_stmt | PASS | PASS | PASS |
| exemplo_bool_ops | PASS | PASS | PASS |
| exemplo_scientific | PASS | PASS | PASS |
| exemplo_multiparams | PASS | PASS | PASS |
| exemplo_void_return | PASS | PASS | PASS |
| test_id_underscore | PASS | PASS | PASS |
| test_id_multi_underscore | PASS | PASS | PASS |
| test_id_mixed_case | PASS | PASS | PASS |
| test_num_integer | PASS | PASS | PASS |
| test_num_scientific_signs | PASS | PASS | PASS |
| test_num_variety | PASS | PASS | PASS |
| test_op_arithmetic | PASS | PASS | PASS |
| test_op_comparison | PASS | PASS | PASS |
| test_op_logical | PASS | PASS | PASS |
| test_prec_arith | PASS | PASS | PASS |
| test_prec_bool | PASS | PASS | PASS |
| test_prec_mixed | PASS | PASS | PASS |
| test_expr_nested_parens | PASS | PASS | PASS |
| test_expr_funcall_in_expr | PASS | PASS | PASS |
| test_expr_bool_literals_in_expr | PASS | PASS | PASS |
| test_cmd_empty_blocks | PASS | PASS | PASS |
| test_cmd_sequential_control | PASS | PASS | PASS |
| test_cmd_print_expressions | PASS | PASS | PASS |
| test_func_bool_params | PASS | PASS | PASS |
| test_func_mixed_params | PASS | PASS | PASS |
| test_func_chain_calls | PASS | PASS | PASS |
| test_func_no_params_expr | PASS | PASS | PASS |
| test_edge_only_decls | PASS | PASS | PASS |
| test_edge_many_funcs | PASS | PASS | PASS |

## Error Program Tests

| Test | Parser | Compiler |
|------|--------|----------|
| exemplo_erro | PASS | PASS |
| exemplo_erro2 | PASS | PASS |
| exemplo_erro3 | PASS | PASS |
| exemplo_erro4 | PASS | PASS |
| test_erro_invalid_char | PASS | PASS |
| test_erro_missing_rparen | PASS | PASS |
| test_erro_missing_end_semi | PASS | PASS |
| test_erro_missing_assign | PASS | PASS |
| test_erro_keyword_as_id | PASS | PASS |
| test_erro_def_no_type | PASS | PASS |
| test_erro_empty_parens_expr | PASS | PASS |
| test_erro_double_semi | PASS | PASS |
| test_erro_missing_lparen_if | PASS | PASS |
| test_erro_missing_main | PASS | PASS |
| test_erro_func_after_main | PASS | PASS |
