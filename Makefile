# Lovelace Compiler -- Development Makefile
# Usage: make [target] [FILTER=pattern] [FILE=path]

.PHONY: build test test-lexer test-parser test-compiler clean report baseline run ast watch help

# Default target
all: build

# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------
build:
	@bash scripts/build.sh

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------
test:
ifdef FILTER
	@bash scripts/test_runner.sh all --no-pager -f "$(FILTER)"
else
	@bash scripts/test_runner.sh all --no-pager
endif

test-lexer:
ifdef FILTER
	@bash scripts/test_runner.sh lexer --no-pager -f "$(FILTER)"
else
	@bash scripts/test_runner.sh lexer --no-pager
endif

test-parser:
ifdef FILTER
	@bash scripts/test_runner.sh parser --no-pager -f "$(FILTER)"
else
	@bash scripts/test_runner.sh parser --no-pager
endif

test-compiler:
ifdef FILTER
	@bash scripts/test_runner.sh compiler --no-pager -f "$(FILTER)"
else
	@bash scripts/test_runner.sh compiler --no-pager
endif

# ---------------------------------------------------------------------------
# Utilities
# ---------------------------------------------------------------------------
clean:
	@bash scripts/clean.sh

report:
	@bash scripts/test_report.sh

baseline:
	@bash scripts/generate_expected.sh

run:
ifndef FILE
	@echo "Usage: make run FILE=test/examples/exemplo.lov"
	@exit 1
endif
ifdef FILE
	@bash scripts/run.sh $(FILE)
endif

ast:
ifndef FILE
	@echo "Usage: make ast FILE=test/examples/exemplo.lov [FORMAT=text|dot|png|svg]"
	@exit 1
endif
ifdef FILE
	@bash scripts/ast_diagram.sh $(FILE) --format $(or $(FORMAT),text)
endif

watch:
	@bash scripts/watch.sh

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------
help:
	@echo ""
	@echo "Lovelace Compiler -- Development Targets"
	@echo "========================================="
	@echo ""
	@echo "  make / make build          Compile (javacc + javac)"
	@echo "  make test                  Run ALL tests (lexer + parser + compiler)"
	@echo "  make test-lexer            Run lexer tests only"
	@echo "  make test-parser           Run parser tests only"
	@echo "  make test-compiler         Run compiler tests only"
	@echo "  make test FILTER=pattern   Run only tests matching pattern"
	@echo "  make clean                 Remove compiled classes and generated files"
	@echo "  make report                Generate test/TEST_REPORT.md"
	@echo "  make baseline              Regenerate expected output baselines"
	@echo "  make run FILE=<path>       Run a .lov file through all 3 phases"
	@echo "  make ast FILE=<path>       Generate AST diagram (FORMAT=text|dot|png|svg)"
	@echo "  make watch                 Rebuild + test on src/ file changes"
	@echo "  make help                  Show this help message"
	@echo ""
