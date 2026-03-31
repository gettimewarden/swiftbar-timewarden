#!/usr/bin/env bash
set -euo pipefail

PLUGIN_NAME="timewarden.30s.sh"
CACHE_DIR="$HOME/.cache/xbar-timewarden"

echo "Timewarden xbar Plugin — Uninstaller"
echo "====================================="

# Remove plugin from xbar
PLUGIN_DIR="$HOME/Library/Application Support/xbar/plugins"
if [[ -f "$PLUGIN_DIR/$PLUGIN_NAME" ]]; then
    rm -f "$PLUGIN_DIR/$PLUGIN_NAME"
    echo "Removed plugin from $PLUGIN_DIR"
fi

# Remove cache and config
if [[ -d "$CACHE_DIR" ]]; then
    rm -rf "$CACHE_DIR"
    echo "Removed cache directory $CACHE_DIR"
fi

open "xbar://app.xbarapp.com/refreshAllPlugins" 2>/dev/null || true

echo ""
echo "Done. Plugin uninstalled."
