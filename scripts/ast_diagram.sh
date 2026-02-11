#!/bin/bash
# ast_diagram.sh -- Generate an AST diagram for a .lov file.
#
# Usage:
#   ./scripts/ast_diagram.sh <file.lov> [--format text|dot|png|svg]
#
# Default format is "text" (prints ASCII tree to terminal).

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

cd "$PROJECT_ROOT"

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
FILE=""
FORMAT="text"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --format)
            FORMAT="$2"
            shift 2
            ;;
        *)
            FILE="$1"
            shift
            ;;
    esac
done

if [ -z "$FILE" ]; then
    echo "Usage: ./scripts/ast_diagram.sh <file.lov> [--format text|dot|png|svg]"
    exit 1
fi

if [ ! -f "$FILE" ]; then
    echo "Error: File not found: $FILE"
    exit 1
fi

# ---------------------------------------------------------------------------
# Auto-build if needed
# ---------------------------------------------------------------------------
if [ ! -d "lovelace" ] || [ ! -f "lovelace/Lovelace.class" ]; then
    echo "Classes not found. Building automatically..." >&2
    bash "${SCRIPT_DIR}/build.sh" -q
    if [ $? -ne 0 ]; then
        echo "Error: Auto-build failed. Please run ./scripts/build.sh manually." >&2
        exit 1
    fi
    echo "" >&2
fi

# ---------------------------------------------------------------------------
# Text mode: just print to terminal
# ---------------------------------------------------------------------------
if [ "$FORMAT" = "text" ]; then
    java lovelace.LovelaceASTDiagram "$FILE"
    exit $?
fi

# ---------------------------------------------------------------------------
# DOT-based formats (dot, png, svg)
# ---------------------------------------------------------------------------
BASE=$(basename "$FILE" .lov)
DIR=$(dirname "$FILE")
DOT_FILE="${DIR}/${BASE}_ast.dot"

java lovelace.LovelaceASTDiagram "$FILE" --dot > "$DOT_FILE"
if [ $? -ne 0 ]; then
    echo "Error: Failed to generate AST."
    rm -f "$DOT_FILE"
    exit 1
fi

echo "DOT file generated: $DOT_FILE"

if [ "$FORMAT" = "dot" ]; then
    exit 0
fi

# Render with Graphviz (png/svg)
if ! command -v dot &> /dev/null; then
    echo ""
    echo "Graphviz is not installed. To render the diagram, install it:"
    echo ""
    echo "  macOS:   brew install graphviz"
    echo "  Ubuntu:  sudo apt install graphviz"
    echo ""
    echo "Then run:  dot -T${FORMAT} ${DOT_FILE} -o ${DIR}/${BASE}_ast.${FORMAT}"
    exit 0
fi

OUTPUT_FILE="${DIR}/${BASE}_ast.${FORMAT}"
dot -T"${FORMAT}" "$DOT_FILE" -o "$OUTPUT_FILE"

if [ $? -ne 0 ]; then
    echo "Error: Graphviz rendering failed."
    exit 1
fi

echo "Diagram rendered: $OUTPUT_FILE"

# On macOS, offer to open the image
if [[ "$OSTYPE" == "darwin"* ]] && [ -t 1 ]; then
    open "$OUTPUT_FILE" 2>/dev/null
fi
