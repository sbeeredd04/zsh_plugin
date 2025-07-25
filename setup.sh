#!/bin/bash

# setup.sh - Automatic setup script for zsh autocomplete plugin

set -e  # Exit on any error

echo "🔧 Setting up Zsh Autocomplete Plugin..."

# Get the absolute path of the plugin directory
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "📁 Plugin directory: $PLUGIN_DIR"

# Clean and build the C program
echo "🏗️  Building autocomplete binary..."
make clean 2>/dev/null || true
make

# Check if binary was created successfully
if [ ! -f "$PLUGIN_DIR/autocomplete" ]; then
    echo "❌ Error: autocomplete binary not found after build"
    exit 1
fi

# Test the binary
echo "🧪 Testing binary..."
if ./autocomplete >/dev/null 2>&1; then
    echo "✅ Binary test passed"
else
    echo "❌ Binary test failed"
    exit 1
fi

# Backup existing .zshrc
if [ -f ~/.zshrc ]; then
    cp ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d_%H%M%S)
    echo "💾 Backed up existing .zshrc"
fi

# Check if plugin is already sourced in .zshrc
PLUGIN_LINE="source $PLUGIN_DIR/plugin.zsh"
if grep -Fq "$PLUGIN_LINE" ~/.zshrc 2>/dev/null; then
    echo "⚠️  Plugin already configured in .zshrc"
else
    echo "" >> ~/.zshrc
    echo "# Zsh Autocomplete Plugin" >> ~/.zshrc
    echo "$PLUGIN_LINE" >> ~/.zshrc
    echo "✅ Added plugin to .zshrc"
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "1. Restart your terminal OR run: source ~/.zshrc"
echo "2. Use ↑/↓ arrow keys to navigate command history"
echo "3. Test with any command and use arrows to browse history"
echo ""
echo "To uninstall: Remove the plugin line from ~/.zshrc and restore backup" 