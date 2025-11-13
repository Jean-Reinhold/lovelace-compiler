# Lovelace Compiler

Lexical and syntax analyzer implementation for the Lovelace language using JavaCC.

## What's in here

- **Lexical Analyzer**: tokenizes Lovelace programs, showing all tokens found
- **Syntax Analyzer**: validates program syntax, checking if they're correct

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

## Project Structure

```
lovelace-compiler/
├── src/lovelace/
│   ├── Lovelace.jj              # Grammar with tokens and production rules
│   ├── Lovelace.java             # Lexical analyzer
│   └── LovelaceSintatico.java    # Syntax analyzer
├── test/
│   ├── examples/                 # Example programs
│   ├── expected/                 # Expected lexer outputs
│   └── expected_sintatico/        # Expected parser outputs
└── scripts/
    ├── build.sh                  # Builds everything
    ├── test.sh                   # Tests the lexer
    ├── test_sintatico.sh         # Tests the parser
    ├── run.sh                    # Runs lexer interactively
    └── run_sintatico.sh          # Runs parser interactively
```

## Building

Run the build script:

```bash
./scripts/build.sh
```

This will generate Java files from JavaCC and compile everything.

## Usage

### Lexical Analyzer

Tokenizes the program and shows all tokens:

```bash
java lovelace.Lovelace test/examples/exemplo.lov
```

Or use the interactive script:

```bash
./scripts/run.sh
```

### Syntax Analyzer

Validates program syntax:

```bash
java lovelace.LovelaceSintatico test/examples/exemplo.lov
```

If everything is correct, it shows:
```
Análise sintática concluída com sucesso!
```

If there's an error, it shows the line and column of the problem.

Or use the interactive script:

```bash
./scripts/run_sintatico.sh
```

## Testing

### Test the Lexer

```bash
./scripts/test.sh
```

Runs all examples and compares with expected outputs.

### Test the Parser

```bash
./scripts/test_sintatico.sh
```

Validates that all example programs are syntactically correct.

## Recognized Tokens

### Reserved Words
`main`, `begin`, `end`, `let`, `Float`, `Bool`, `Void`, `if`, `while`, `read`, `return`, `print`, `def`, `true`, `false`

### Operators
- Arithmetic: `+`, `-`, `*`, `/`
- Logical: `&&`, `||`
- Comparison: `<`, `>`, `==`
- Assignment: `:=`

### Other
- Identifiers: letter followed by letters/digits, can have underscores
- Numbers: integers, decimals and scientific notation (e.g., `123`, `45.67`, `1.5E10`)
- Punctuation: `(`, `)`, `;`, `,`

## Examples

There are three ready-to-use examples:
- `exemplo.lov`: basic, just declares a variable and prints
- `exemplo1.lov`: variables, conditionals, expressions
- `exemplo2.lov`: functions, loops, function calls

All are in `test/examples/`.

## Lexer Output

The lexical analyzer shows each token found:

```
Palavra reservada: main
Abre parênteses: (
Fecha parênteses: )
Palavra reservada: begin
Palavra reservada: let
Palavra reservada: Float
Identificador: teste
Ponto e virgula: ;
...
```

## Parser Output

The syntax analyzer only shows if it succeeded or not:

**Success:**
```
Análise sintática concluída com sucesso!
```

**Error:**
```
Erro de sintaxe na linha 4, coluna 12: ...
```
