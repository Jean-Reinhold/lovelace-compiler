# Lovelace Compiler

A compiler for the Lovelace language, built with JavaCC. Includes a lexical analyzer, syntax analyzer (parser), and code generator that produces C output.

## Requirements

- Java JDK 8 or higher
- JavaCC

### Installing JavaCC

**macOS:**
```bash
brew install javacc
```

**Linux:**
```bash
sudo apt-get install javacc
```

Or download directly from: https://javacc.github.io/javacc/

## Quick Start

```bash
make build                # compile everything
make test                 # run the full test suite
make help                 # see all available targets
```

## Project Structure

```
lovelace-compiler/
├── Makefile                      # Single entry point for all dev tasks
├── src/
│   ├── lovelace/
│   │   ├── Lovelace.jj           # Grammar with tokens and production rules
│   │   ├── Lovelace.java         # Lexical analyzer entry point
│   │   ├── LovelaceSintatico.java # Syntax analyzer entry point
│   │   └── LovelaceCompiler.java  # Code generator entry point
│   └── ast/                      # Abstract Syntax Tree node classes
├── test/
│   ├── examples/                 # .lov test programs (51 files)
│   ├── expected/                 # Expected lexer outputs
│   ├── expected_sintatico/       # Expected parser outputs
│   └── expected_compiler/        # Expected compiler outputs (.c files)
└── scripts/
    ├── build.sh                  # Build script (javacc + javac)
    ├── test_runner.sh            # Unified test runner (all phases)
    ├── run.sh                    # Interactive runner (all phases)
    ├── clean.sh                  # Remove build artifacts
    ├── watch.sh                  # Watch mode: rebuild + test on changes
    ├── generate_expected.sh      # Regenerate expected output baselines
    ├── test_report.sh            # Generate Markdown test report
    ├── test_discover.sh          # Auto-discover and classify tests
    └── test_lib.sh               # Shared test formatting library
```

## Building

```bash
make build
```

This generates the parser from the JavaCC grammar and compiles all Java sources. Use `make clean` to remove all compiled classes and generated files.

## Usage

### Run a file through all phases

```bash
make run FILE=test/examples/exemplo.lov
```

### Run a specific phase

```bash
# Lexer -- tokenizes the program
java lovelace.Lovelace test/examples/exemplo.lov

# Parser -- validates syntax
java lovelace.LovelaceSintatico test/examples/exemplo.lov

# Compiler -- generates C code
java lovelace.LovelaceCompiler test/examples/exemplo.lov
```

### Interactive mode

```bash
./scripts/run.sh                    # menu to pick a file, runs all phases
./scripts/run.sh lexer              # menu, lexer only
./scripts/run.sh compiler myfile.lov  # specific file, compiler only
```

## Testing

### Run all tests

```bash
make test
```

### Run tests for a single phase

```bash
make test-lexer
make test-parser
make test-compiler
```

### Filter tests by name

```bash
make test FILTER=exemplo     # only tests matching "exemplo"
make test FILTER=erro        # only error tests
make test-parser FILTER=func # only function-related parser tests
```

### Generate test report

```bash
make report    # writes test/TEST_REPORT.md
```

### Regenerate expected baselines

```bash
make baseline
```

### Watch mode

Automatically rebuilds and re-runs the test suite when source files change:

```bash
make watch
```

Uses `fswatch` if available, otherwise polls every 2 seconds.

## All Make Targets

```
make / make build          Compile (javacc + javac)
make test                  Run ALL tests (lexer + parser + compiler)
make test-lexer            Run lexer tests only
make test-parser           Run parser tests only
make test-compiler         Run compiler tests only
make test FILTER=pattern   Run only tests matching pattern
make clean                 Remove compiled classes and generated files
make report                Generate test/TEST_REPORT.md
make baseline              Regenerate expected output baselines
make run FILE=<path>       Run a .lov file through all 3 phases
make watch                 Rebuild + test on src/ file changes
make help                  Show all targets with descriptions
```

## The Lovelace Language

### Reserved Words
`main`, `begin`, `end`, `let`, `Float`, `Bool`, `Void`, `if`, `while`, `read`, `return`, `print`, `def`, `true`, `false`

### Operators
- Arithmetic: `+`, `-`, `*`, `/`
- Logical: `&&`, `||`
- Comparison: `<`, `>`, `==`
- Assignment: `:=`

### Other Tokens
- Identifiers: letter followed by letters/digits, can have underscores
- Numbers: integers, decimals and scientific notation (e.g., `123`, `45.67`, `1.5E10`)
- Punctuation: `(`, `)`, `;`, `,`

## Examples

There are several ready-to-use examples in `test/examples/`:
- `exemplo.lov`: basic program -- declares a variable and prints
- `exemplo1.lov`: variables, conditionals, expressions
- `exemplo2.lov`: functions, loops, function calls

Run any of them with:
```bash
make run FILE=test/examples/exemplo.lov
```
