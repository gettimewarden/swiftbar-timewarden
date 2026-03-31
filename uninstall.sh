#!/usr/bin/env bash
set -euo pipefail

PLUGIN_NAME="timewarden.30s.sh"
CACHE_DIR="$HOME/.cache/swiftbar-timewarden"

echo "Timewarden SwiftBar Plugin — Uninstaller"
echo "========================================="

# Remove plugin from SwiftBar
PLUGIN_DIR=$(defaults read com.ameba.SwiftBar PluginDirectory 2>/dev/null || echo "")
if [[ -n "$PLUGIN_DIR" && -f "$PLUGIN_DIR/$PLUGIN_NAME" ]]; then
    rm -f "$PLUGIN_DIR/$PLUGIN_NAME"
    echo "Removed plugin from $PLUGIN_DIR"
fi

# Remove cache and config
if [[ -d "$CACHE_DIR" ]]; then
    rm -rf "$CACHE_DIR"
    echo "Removed cache directory $CACHE_DIR"
fi

open "swiftbar://refreshallplugins" 2>/dev/null || true

echo ""
echo "Done. Plugin uninstalled."
