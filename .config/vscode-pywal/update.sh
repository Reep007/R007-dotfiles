#!/bin/bash
# Clear the Wal Theme extension's cache to force regeneration
rm -rf ~/.vscode/extensions/dlasagno.wal-theme-*/themes/*
# Optional: Restart VS Code if running (or notify user to reopen)
pkill -u $USER code || true
