# Analisador Léxico para a Linguagem Lovelace

Este projeto implementa um analisador léxico para a Linguagem Lovelace usando JavaCC.

> 📚 **Documentação Completa**: Para uma explicação detalhada passo a passo, consulte [DOCUMENTATION.md](DOCUMENTATION.md)

## Requisitos

- Java JDK (versão 8 ou superior)
- JavaCC (Java Compiler Compiler)

### Instalação do JavaCC

1. Baixe o JavaCC de: https://javacc.github.io/javacc/
2. Extraia o arquivo e adicione o diretório `bin` ao seu PATH, ou
3. Use um gerenciador de pacotes:
   - macOS: `brew install javacc`
   - Linux: `sudo apt-get install javacc` (ou equivalente)

## Estrutura do Projeto

```
lovelace-compiler/
├── src/
│   └── lovelace/
│       ├── Lovelace.jj          # Gramática JavaCC com definições de tokens
│       └── Lovelace.java       # Classe principal que utiliza o lexer gerado
├── test/
│   ├── examples/                # Arquivos de teste Lovelace
│   │   ├── exemplo.lov
│   │   ├── exemplo1.lov
│   │   └── exemplo2.lov
│   └── expected/                # Saídas esperadas para cada teste
│       ├── exemplo.out
│       ├── exemplo1.out
│       └── exemplo2.out
└── scripts/
    ├── build.sh                 # Script de compilação
    ├── test.sh                  # Script de teste (executa todos os testes)
    └── run.sh                   # Script interativo para executar um teste
```

## Compilação

Execute o script de build:

```bash
chmod +x scripts/build.sh
./scripts/build.sh
```

Ou manualmente:

```bash
cd src/lovelace
javacc Lovelace.jj
cd ../..
javac -d . src/lovelace/*.java
```

## Uso

Após compilar, execute o analisador léxico com:

```bash
java lovelace.Lovelace <arquivo.lov>
```

### Exemplos

```bash
# Exemplo básico
java lovelace.Lovelace test/examples/exemplo.lov

# Exemplo 1: Variáveis, atribuições, aritmética e condicionais
java lovelace.Lovelace test/examples/exemplo1.lov

# Exemplo 2: Funções, loops, operações booleanas e chamadas de função
java lovelace.Lovelace test/examples/exemplo2.lov
```

## Testes

### Executar todos os testes

Execute o script de teste para verificar se a saída do analisador corresponde às saídas esperadas:

```bash
chmod +x scripts/test.sh
./scripts/test.sh
```

O script executa todos os exemplos e compara as saídas com os arquivos esperados em `test/expected/`.

### Executar um teste interativamente

Para executar um teste específico de forma interativa:

```bash
chmod +x scripts/run.sh
./scripts/run.sh
```

O script exibirá um menu com todos os testes disponíveis e permitirá que você selecione qual executar.

## Tokens Reconhecidos

### Palavras Reservadas
- `main`, `begin`, `end`, `let`, `Float`, `Bool`, `Void`
- `if`, `while`, `read`, `return`, `print`, `def`
- `true`, `false`

### Operadores
- Aritméticos: `+`, `-`, `*`, `/`
- Lógicos: `&&`, `||`
- Comparação: `<`, `>`, `==`
- Atribuição: `:=`

### Pontuação
- `(`, `)`, `;`, `,`

### Outros
- Identificadores: letra seguida de letras, dígitos ou sublinhados
- Números: inteiros, decimais e notação científica (ex: `123`, `45.67`, `1.5E10`)

## Formato de Saída

O analisador imprime cada token encontrado no formato:

```
Tipo do token: valor
```

Exemplo:
```
Palavra reservada: main
Abre parênteses: (
Fecha parênteses: )
Identificador: teste
Atribuição: :=
Número: 9.0
Ponto e virgula: ;
```
