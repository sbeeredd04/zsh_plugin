# zsh_plugin (Hybrid Zsh+C Example)

A hybrid Zsh+C plugin that inserts "Hello from C!" at the cursor when you press a keybinding. This demonstrates how to combine C's performance with Zsh's integration capabilities.

## Directory Structure
```
zsh_plugin/
├── hello.c          # C source code
├── plugin.zsh       # Zsh widget and keybinding
├── Makefile         # Build configuration
├── hello            # Compiled binary (created after make)
└── README.md        # This file
```

## Quick Start

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

4. **Test it:** Press `Ctrl-x Ctrl-h` at any command prompt to insert "Hello from C!"

## How It Works

• The Zsh widget (`hello_widget`) executes the compiled C program
• The C program's output is captured and inserted at the cursor position
• The keybinding `Ctrl-x Ctrl-h` triggers the widget
• You can pass shell variables like `$LBUFFER` to the C program for advanced features

## Testing

Test the C program directly:
```sh
./hello
# Output: Hello from C!
```

Test the plugin integration:
```sh
# Source the plugin
source /Users/sriujjwalreddyb/zsh_plugin/plugin.zsh

# Press Ctrl-x Ctrl-h at your prompt
# You should see "Hello from C!" inserted at cursor
```

## Development

**Rebuild after changes:**
```sh
make clean && make
```

**Clean build artifacts:**
```sh
make clean
```

## Extending the Plugin

### Pass Buffer Context to C Program
Modify the widget in `plugin.zsh`:
```sh
hello_widget() {
  local output
  output="$($ZSH_PLUGIN_BIN "$LBUFFER")"  # Pass current buffer
  LBUFFER+="$output"
}
```

### Access Arguments in C
In `hello.c`, use `argv[1]` to access the buffer:
```c
int main(int argc, char *argv[]) {
    if (argc > 1) {
        printf("Current buffer: %s\n", argv[1]);
    }
    printf("Hello from C!");
    return 0;
}
```

### Advanced Use Cases
- **Command completion:** Implement trie data structures in C for fast lookups
- **History analysis:** Process command history for intelligent suggestions  
- **Text processing:** Use C for heavy string manipulation tasks
- **System integration:** Call system APIs efficiently from C

## Keybinding Reference

- `Ctrl-x Ctrl-h` - Insert "Hello from C!" at cursor
- Customize by changing `bindkey '^x^h'` in `plugin.zsh`

## Troubleshooting

**Plugin not working?**
- Ensure the binary is built: `ls -la hello`
- Check plugin is sourced: `which hello_widget`
- Verify keybinding: `bindkey | grep hello`

**Build errors?**
- Check gcc is installed: `gcc --version`
- Ensure make is available: `make --version`

---

🟢 **This is the simplest, most robust way to combine C performance with Zsh integration.**

Ready to build more advanced features like intelligent autocompletion, command suggestions, or text processing tools!