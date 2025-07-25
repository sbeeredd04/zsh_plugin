# Zsh Autocomplete Plugin (Hybrid Zsh+C)

A hybrid Zsh+C autocomplete plugin that provides command history navigation using up/down arrow keys with **real zsh history**. This demonstrates how to combine C's performance with Zsh's integration capabilities for enhanced command-line experience.

## Directory Structure
```
zsh_plugin/
├── autocomplete.c      # C source code for history processing
├── plugin.zsh          # Zsh widget and keybinding logic
├── Makefile           # Build configuration
├── setup.sh           # Automatic setup script
├── autocomplete       # Compiled binary (created after make)
└── README.md          # This file
```

## Quick Start

**Automatic Setup (Recommended):**
```sh
./setup.sh
```
This script will:
- Build the C program
- Backup your existing `.zshrc`
- Add the plugin to your `.zshrc`
- Test the installation

**Manual Setup:**
1. **Build the C program:**
   ```sh
   make
   ```

2. **Add to your `.zshrc`:**
   ```sh
   source /Users/sriujjwalreddyb/zsh_plugin/plugin.zsh
   ```

3. **Reload your shell:**
   ```sh
   source ~/.zshrc
   ```

## How It Works

### Architecture
- **Zsh widgets** capture up/down arrow key presses
- **History extraction** uses `fc -l 1` to get full zsh command history
- **C program** receives history via stdin and handles navigation logic
- **Buffer replacement** updates the command line with selected history entry

### Key Components

1. **`autocomplete.c`**: 
   - Receives: current buffer, direction (up/down), and full history via stdin
   - Processes: up to 1000 history entries from zsh
   - Returns: appropriate history command based on navigation direction

2. **`plugin.zsh`**:
   - `get_zsh_history()`: Extracts real zsh history using `fc` command
   - Defines `autocomplete_up_widget()` and `autocomplete_down_widget()`
   - Binds widgets to up/down arrow keys (`^[[A` and `^[[B`)
   - Manages cursor positioning and buffer updates

3. **Real History Integration**:
   - Uses zsh's built-in `fc` command to access command history
   - Processes the same history that zsh uses internally
   - Supports up to 1000 recent commands
   - Compatible with macOS and Linux

## Usage

- **↑ Arrow**: Navigate to previous/older commands in your actual zsh history
- **↓ Arrow**: Navigate to next/newer commands in your actual zsh history
- **Navigation**: Cycles through your real command history
- **Buffer Update**: Replaces entire command line with selected history

## Real History Features
✅ **Uses your actual zsh history** - No demo data
✅ **Same history as zsh** - Accesses via `fc` command
✅ **Recent commands first** - History is reversed for intuitive navigation
✅ **Cross-platform** - Works on macOS and Linux
✅ **Fast processing** - C handles up to 1000 entries efficiently

## Testing

**Test the C program with real history:**
```sh
fc -l 1 | awk '{$1=""; print substr($0,2)}' | tail -r | ./autocomplete "test" "up"
fc -l 1 | awk '{$1=""; print substr($0,2)}' | tail -r | ./autocomplete "test" "down"
```

**Test the plugin:**
1. Source the plugin: `source plugin.zsh`
2. Type any command (or leave blank)
3. Press ↑/↓ arrows to navigate through your actual command history

## Development

**Rebuild after changes:**
```sh
make clean && make
```

**Clean build artifacts:**
```sh
make clean
```

**Quick test setup:**
```sh
./setup.sh
```

## Technical Details

### History Processing
- **Extraction**: `fc -l 1` gets full numbered history
- **Cleaning**: `awk` removes line numbers, keeping only commands
- **Ordering**: `tail -r` reverses for newest-first navigation
- **Limits**: C program handles up to 1000 entries (configurable)

### Navigation Logic
- **Up Arrow**: Move to older commands (increment index)
- **Down Arrow**: Move to newer commands (decrement index)
- **Circular**: Navigation wraps around at history boundaries
- **State**: Each widget call processes fresh history

## Advanced Features (Future)

- **Smart filtering**: Match commands based on current buffer prefix
- **Frequency-based sorting**: Most used commands first
- **Context awareness**: Different history per directory
- **Fuzzy matching**: Partial command completion
- **Custom categories**: Group commands by type
- **Persistent indexing**: Remember position across sessions

## Troubleshooting

**Plugin not working?**
- Run `./setup.sh` to ensure proper installation
- Check binary exists: `ls -la autocomplete`
- Verify plugin loaded: `which autocomplete_up_widget`
- Test manually: `echo "test cmd" | ./autocomplete "buffer" "up"`

**No history showing?**
- Check zsh history: `fc -l 1 | head -5`
- Verify history settings: `echo $HISTSIZE $SAVEHIST`
- Test extraction: `fc -l 1 | awk '{$1=""; print substr($0,2)}' | tail -r | head -5`

**Arrow keys not working?**
- Check terminal type: `echo $TERM`
- Try alternative bindings in `plugin.zsh`
- Test key codes: `cat -v` (then press arrows)

**Build errors?**
- Check gcc: `gcc --version`
- Ensure make available: `make --version`
- Check file permissions: `ls -la autocomplete.c`

## Keybinding Reference

- `↑` (Up Arrow) - Navigate to older commands in real history
- `↓` (Down Arrow) - Navigate to newer commands in real history
- Bindings: `^[[A`, `^[[B`, `^[OA`, `^[OB`

---

🟢 **Now using your real zsh command history for seamless navigation!**

The plugin integrates with zsh's built-in history system, providing the same commands you see with the default history navigation, but with enhanced C-powered processing capabilities.