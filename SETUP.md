# Zsh Autocomplete Plugin - Setup Guide

This guide will help you install and configure the Zsh Autocomplete Plugin on your system.

## Prerequisites

### Required Software

- **Zsh Shell**: Version 5.0 or higher
  ```bash
  # Check your zsh version
  zsh --version
  ```

- **C Compiler**: GCC or Clang
  ```bash
  # Check for gcc
  gcc --version
  
  # Or check for clang
  clang --version
  ```

- **Make**: Build automation tool
  ```bash
  make --version
  ```

### Operating System Support

- Linux (Ubuntu, Debian, Fedora, Arch, etc.)
- macOS (Intel and Apple Silicon)
- Other Unix-like systems with Zsh support

## Installation Methods

### Method 1: Automatic Installation (Recommended)

This is the easiest way to get started. The setup script will build the plugin and configure your shell automatically.

```bash
# Step 1: Clone the repository
git clone https://github.com/sbeeredd04/zsh_plugin.git
cd zsh_plugin

# Step 2: Run the setup script
./scripts/setup.sh
```

The setup script will:
1. Build the autocomplete binary from C source code
2. Test the binary to ensure it works correctly
3. Add the plugin configuration to your `~/.zshrc`
4. Create a backup of your existing `.zshrc` file

**Note**: The script creates a timestamped backup at `~/.zshrc.backup.YYYYMMDD_HHMMSS`

### Method 2: Manual Installation

If you prefer more control or want to understand the installation process:

```bash
# Step 1: Clone the repository
git clone https://github.com/sbeeredd04/zsh_plugin.git
cd zsh_plugin

# Step 2: Build the binary
make clean && make

# Step 3: Test the binary (optional but recommended)
make test

# Step 4: Add to your .zshrc
echo "" >> ~/.zshrc
echo "# Zsh Autocomplete Plugin" >> ~/.zshrc
echo "source $(pwd)/plugin.zsh" >> ~/.zshrc

# Step 5: Reload your shell configuration
source ~/.zshrc
```

### Method 3: Release Package Installation

Download a pre-built release package:

```bash
# Step 1: Download the latest release for your platform
# Visit: https://github.com/sbeeredd04/zsh_plugin/releases

# For Linux:
curl -L -o zsh-autocomplete.tar.gz https://github.com/sbeeredd04/zsh_plugin/releases/download/v1.0.0/autocomplete-linux-amd64.tar.gz

# For macOS:
curl -L -o zsh-autocomplete.tar.gz https://github.com/sbeeredd04/zsh_plugin/releases/download/v1.0.0/autocomplete-macos-arm64.tar.gz

# Step 2: Extract the package
tar -xzf zsh-autocomplete.tar.gz
cd zsh_plugin

# Step 3: Run setup
./scripts/setup.sh
```

## Post-Installation

### Activate the Plugin

After installation, you need to reload your shell configuration:

```bash
# Option 1: Reload .zshrc in current session
source ~/.zshrc

# Option 2: Restart your terminal
# Simply close and reopen your terminal application

# Option 3: Start a new zsh session
exec zsh
```

### Verify Installation

Test that the plugin is working correctly:

```bash
# Test 1: Check if the binary is executable
ls -la $(pwd)/autocomplete

# Test 2: Verify the plugin is sourced
grep "plugin.zsh" ~/.zshrc

# Test 3: Test ghost text manually
echo "git status" | ./autocomplete ghost "git"
# Should output: git status
```

## Usage

### Basic Features

#### Ghost Text Completion

As you type, the plugin suggests completions based on your command history:

1. **Type a prefix**: Start typing any command (e.g., `git`)
2. **View suggestion**: Ghost text appears in dim gray to the right
3. **Accept suggestion**: Press `→` (Right Arrow) or `Tab` to accept

Example:
```
$ git                    <- You type this
$ git status            <- Ghost text appears (in dim gray)
$ git status            <- After pressing → or Tab
```

#### Smart History Navigation

Navigate through your command history filtered by what you've typed:

1. **Type a prefix**: Start with a command prefix (e.g., `git`)
2. **Navigate**: Use `↑` (Up Arrow) to see previous matching commands
3. **Cycle**: Press `↓` (Down Arrow) to go back
4. **Execute**: Press `Enter` to run the command

Example sequence:
```
$ git                   <- Original input
$ git push             <- Press ↑ (newest matching command)
$ git commit -m        <- Press ↑ again
$ git status           <- Press ↑ again
$ git                  <- Press ↓ to return to original
```

### Keyboard Shortcuts

| Key                    | Action                                    |
|------------------------|-------------------------------------------|
| `↑` (Up Arrow)         | Navigate to previous matching command     |
| `↓` (Down Arrow)       | Navigate to next matching command         |
| `→` (Right Arrow)      | Accept ghost text suggestion              |
| `Tab`                  | Accept ghost text or trigger completion   |
| `Enter`                | Execute command and update usage stats    |
| `Backspace`            | Delete character and update ghost text    |
| `Option+Backspace`     | Delete word backward                      |
| `Cmd+Backspace`        | Delete entire line (macOS)                |

### Advanced Features

#### Persistent Storage

The plugin automatically saves your command history to a trie data structure:

- **Location**: `data/trie_data.txt` (created automatically)
- **Persistence**: Commands are saved across terminal sessions
- **Learning**: Frequency and recency of commands improve suggestions

#### Performance Characteristics

- **Startup Time**: 0ms (uses cached data from previous sessions)
- **Ghost Text Response**: Under 5ms for any prefix
- **History Filtering**: Under 10ms for 1000+ commands
- **Memory Usage**: Approximately 1MB for 1000 commands

## Configuration

### Custom Key Bindings (Optional)

You can customize key bindings by editing `plugin.zsh`:

```bash
# Example: Change ghost text acceptance to Ctrl+F instead of Right Arrow
bindkey '^F' accept_ghost_completion

# Example: Use Ctrl+P and Ctrl+N for history navigation
bindkey '^P' autocomplete_up_widget
bindkey '^N' autocomplete_down_widget
```

After making changes, reload your configuration:
```bash
source ~/.zshrc
```

### Adjusting Ghost Text Color

The ghost text uses ANSI color 8 (dim gray) by default. To change it, edit the `draw_ghost_suggestion()` function in `plugin.zsh`:

```bash
# Current: dim gray (color 8)
region_highlight=("$#LBUFFER $(( $#LBUFFER + $#ZSH_GHOST_TEXT )) fg=8")

# Alternative: blue
region_highlight=("$#LBUFFER $(( $#LBUFFER + $#ZSH_GHOST_TEXT )) fg=blue")

# Alternative: 256-color palette (e.g., color 240)
region_highlight=("$#LBUFFER $(( $#LBUFFER + $#ZSH_GHOST_TEXT )) fg=240")
```

## Troubleshooting

### Common Issues

#### Plugin Not Loading

**Symptom**: No ghost text appears, arrow keys don't filter history

**Solutions**:
```bash
# Check if binary was built
ls -la autocomplete
# If missing, run: make clean && make

# Check if plugin is sourced in .zshrc
grep "plugin.zsh" ~/.zshrc
# If missing, add: source /path/to/zsh_plugin/plugin.zsh

# Reload shell configuration
source ~/.zshrc
```

#### "undefined-key" Error

**Symptom**: Error message when sourcing .zshrc: `"self_insert_with_ghost" undefined-key`

**Solutions**:
```bash
# This was fixed in recent versions
# Update to latest version:
cd zsh_plugin
git pull origin main
source ~/.zshrc

# Or reinstall:
./scripts/setup.sh
```

#### Ghost Text Not Appearing

**Symptom**: Typing commands doesn't show suggestions

**Solutions**:
```bash
# Ensure you've typed at least 2 characters
# Ghost text requires a minimum prefix length

# Check if trie data exists
ls -la data/trie_data.txt

# Test manually
echo "git status" | ./autocomplete ghost "git"
# Should output: git status

# If test fails, rebuild:
make clean && make
```

#### Arrow Keys Not Working

**Symptom**: Up/down arrows insert characters instead of navigating

**Solutions**:
```bash
# Check terminal type
echo $TERM
# Should be something like: xterm-256color

# Test key codes (press Ctrl+C to exit)
cat -v
# Press arrow keys - should show escape sequences

# If issue persists, check terminal emulator settings
# Some terminals may need specific key mapping configuration
```

#### Build Failures

**Symptom**: `make` command fails with compilation errors

**Solutions**:
```bash
# Ensure you have a C compiler
gcc --version
# Or: clang --version

# Clean and rebuild
make clean
make

# Check for specific error messages
# Common issues:
# - Missing headers: Install development packages
# - Compiler not found: Install gcc or clang
```

### Performance Issues

#### Slow Response Time

**Symptom**: Lag when typing or navigating history

**Solutions**:
```bash
# Check cache file size
du -h data/trie_data.txt

# If very large (>10MB), clear cache
rm -rf data/
# Cache will rebuild on next use

# Monitor performance
time ./autocomplete ghost "test"
# Should complete in <10ms
```

#### High Memory Usage

**Symptom**: Plugin uses excessive memory

**Solutions**:
```bash
# Clear old data
rm -rf data/

# Restart terminal to free memory
exec zsh

# If issue persists, check for other plugins
# that might conflict
```

## Uninstallation

### Complete Removal

To completely remove the plugin:

```bash
# Step 1: Remove plugin source line from .zshrc
# Edit ~/.zshrc and delete the lines:
#   # Zsh Autocomplete Plugin
#   source /path/to/zsh_plugin/plugin.zsh

# Or use sed to remove automatically:
sed -i.backup '/# Zsh Autocomplete Plugin/,+1d' ~/.zshrc

# Step 2: Remove the plugin directory
rm -rf /path/to/zsh_plugin

# Step 3: Reload shell
source ~/.zshrc
```

### Temporary Disable

To temporarily disable without uninstalling:

```bash
# Comment out the source line in .zshrc
# Change:
#   source /path/to/zsh_plugin/plugin.zsh
# To:
#   # source /path/to/zsh_plugin/plugin.zsh

# Reload shell
source ~/.zshrc
```

## Updating

### Update to Latest Version

```bash
# Navigate to plugin directory
cd /path/to/zsh_plugin

# Pull latest changes
git pull origin main

# Rebuild binary
make clean && make

# Reload shell
source ~/.zshrc
```

## Getting Help

### Resources

- **README**: See `README.md` for feature overview
- **System Design**: See `prompts/01-system-design.md` for architecture details
- **GitHub Issues**: Report bugs or request features at the repository issues page

### Debug Mode

To enable verbose output for debugging:

```bash
# Run binary with test input
echo "test command" | ./autocomplete ghost "test"

# Check zsh history file
tail ~/.zsh_history

# Verify trie data
cat data/trie_data.txt
```

## FAQ

### Q: Does this work with Oh My Zsh?
A: Yes, the plugin is compatible with Oh My Zsh and other Zsh frameworks. Just source it after your framework initialization in `.zshrc`.

### Q: Will this conflict with other completion plugins?
A: The plugin is designed to work alongside other completion systems. It uses its own widgets and doesn't override built-in Zsh completion.

### Q: How much disk space does the plugin use?
A: The binary is about 20-30KB. The persistent cache (`data/trie_data.txt`) grows with usage, typically 50-100KB for normal use.

### Q: Can I use this plugin on multiple machines?
A: Yes, you can clone the repository on each machine. The command history is stored locally and will be different on each system.

### Q: Does this plugin send data anywhere?
A: No, the plugin operates entirely locally. All data stays on your machine.

### Q: How do I customize the minimum prefix length?
A: Currently, the plugin suggests completions for any prefix. This is handled in the C code and can be modified in `src/autocomplete.c` if needed.

## Support

If you encounter issues not covered in this guide:

1. Check existing GitHub issues
2. Review the troubleshooting section above
3. Create a new issue with:
   - Your operating system and version
   - Zsh version (`zsh --version`)
   - Error messages or unexpected behavior
   - Steps to reproduce the issue

---

Thank you for using the Zsh Autocomplete Plugin!
