#!/bin/bash

# setup.sh - Simple setup script for Zsh Autocomplete Plugin

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZSHRC_FILE="$HOME/.zshrc"

echo "Setting up Zsh Autocomplete Plugin..."
echo "Plugin directory: $PLUGIN_DIR"

# Build the plugin
echo "Building autocomplete binary..."
cd "$PLUGIN_DIR"
make clean && make

if [[ $? -ne 0 ]]; then
    echo "[ERROR] Build failed. Please check for errors."
    exit 1
fi

# Test the binary
echo "Testing binary..."
if echo -e "git status\ngit commit" | ./autocomplete ghost "git" > /dev/null 2>&1; then
    echo "[SUCCESS] Binary test passed"
else
    echo "[ERROR] Binary test failed"
    exit 1
fi

# Add to zshrc if not already present
if ! grep -q "zsh_plugin/plugin.zsh" "$ZSHRC_FILE"; then
    echo "Adding plugin to $ZSHRC_FILE..."
    
    # Backup existing zshrc
    cp "$ZSHRC_FILE" "$ZSHRC_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Add plugin source line
    echo "" >> "$ZSHRC_FILE"
    echo "# Zsh Autocomplete Plugin" >> "$ZSHRC_FILE"
    echo "source \"$PLUGIN_DIR/plugin.zsh\"" >> "$ZSHRC_FILE"
    
    echo "[SUCCESS] Added to $ZSHRC_FILE (backup created)"
else
    echo "[INFO] Plugin already configured in $ZSHRC_FILE"
fi

echo ""
echo "Setup complete!"
echo ""
echo "To use the plugin:"
echo "1. Restart your terminal or run: source ~/.zshrc"
echo "2. Start typing a command and see ghost text appear (in dim gray)"
echo "3. Use ↑/↓ arrows to navigate filtered history"
echo "4. Use → arrow or Tab to accept ghost text completions"
echo "5. Use Cmd+Backspace or Option+Backspace for word deletion"
echo ""
echo "Features:"
echo "- Ghost text completion with dim gray styling"
echo "- Smart history navigation filtered by prefix"
echo "- Persistent storage (commands saved to data/ directory)"
echo "- Fast C-powered processing"
echo "- Proper backspace support for word and line deletion" 