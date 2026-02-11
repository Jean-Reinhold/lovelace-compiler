#!/bin/bash
# watch.sh -- Watch src/ for changes, auto-rebuild and run tests.
# Uses fswatch if available, otherwise falls back to polling.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

cd "$PROJECT_ROOT"

POLL_INTERVAL=2  # seconds

rebuild_and_test() {
    echo ""
    echo "=========================================="
    echo "  Change detected -- rebuilding..."
    echo "=========================================="
    echo ""

    bash "${SCRIPT_DIR}/build.sh" -q
    if [ $? -ne 0 ]; then
        echo "Build FAILED."
        return 1
    fi

    echo "Build OK. Running tests..."
    echo ""
    bash "${SCRIPT_DIR}/test_runner.sh" all --no-pager
}

# ---------------------------------------------------------------------------
# fswatch mode
# ---------------------------------------------------------------------------
if command -v fswatch &>/dev/null; then
    echo "Watching src/ for changes (fswatch)... Press Ctrl+C to stop."
    fswatch -r -1 --event Created --event Updated --event Removed src/ | while read -r _; do
        # Drain remaining events in this batch
        while read -r -t 0.5 _; do :; done
        rebuild_and_test
        echo ""
        echo "Watching src/ for changes... Press Ctrl+C to stop."
    done
else
    # ---------------------------------------------------------------------------
    # Polling fallback
    # ---------------------------------------------------------------------------
    echo "fswatch not found, using polling (every ${POLL_INTERVAL}s)... Press Ctrl+C to stop."

    get_checksum() {
        find src -name "*.java" -o -name "*.jj" 2>/dev/null | sort | xargs stat -f "%m %N" 2>/dev/null || \
        find src -name "*.java" -o -name "*.jj" 2>/dev/null | sort | xargs stat -c "%Y %n" 2>/dev/null
    }

    LAST_CHECKSUM=$(get_checksum)

    while true; do
        sleep "$POLL_INTERVAL"
        CURRENT_CHECKSUM=$(get_checksum)
        if [ "$CURRENT_CHECKSUM" != "$LAST_CHECKSUM" ]; then
            LAST_CHECKSUM="$CURRENT_CHECKSUM"
            rebuild_and_test
            echo ""
            echo "Watching src/ for changes... Press Ctrl+C to stop."
        fi
    done
fi
