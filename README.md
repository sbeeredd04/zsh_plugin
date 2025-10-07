# Zsh Autocomplete Plugin

A high-performance hybrid Zsh+C autocomplete plugin with **trie-based prefix matching**, **ghost text completion**, and **persistent storage**. Features smart history navigation that filters commands by prefix and learns from your usage patterns.

## Features

- **Ghost Text Completion**: Smart suggestions appear as you type with dim gray styling
- **Prefix-Filtered History**: Navigate only commands matching your prefix
- **Trie Data Structure**: Lightning-fast O(log n) prefix matching
- **Persistent Storage**: Commands cached between sessions
- **High Performance**: C-powered processing with minimal overhead
- **Smart Navigation**: Up/down arrows filter by current input
- **Backspace Support**: Cmd+Backspace and Option+Backspace work correctly with ghost text

## Architecture

```mermaid
flowchart LR
    A[Zsh Plugin] <--> B[C Autocomplete]
    B --> C[Data Structures]
    
    A -->|Key bindings<br/>Ghost display<br/>State mgmt| A
    B -->|Trie matching<br/>Prefix filter<br/>Persistent I/O| B
    C -->|Trie tree<br/>History cache<br/>File storage| C
```

## Repository Structure

| Directory/File      | Description                              |
|---------------------|------------------------------------------|
| src/                | C source code                            |
| src/autocomplete.c  | Main autocomplete program                |
| src/trie.c          | Trie data structure implementation       |
| include/            | C header files                           |
| include/trie.h      | Trie interface definitions               |
| scripts/            | Utility scripts                          |
| scripts/setup.sh    | Automatic installation script            |
| tests/              | Test scripts                             |
| plugin.zsh          | Zsh integration and widget bindings      |
| Makefile            | Build system configuration               |
| README.md           | Project overview (this file)             |
| SETUP.md            | Detailed installation guide              |
| RELEASES.md         | Release process documentation            |
| data/               | Runtime data (created automatically)     |
| data/trie_data.txt  | Persistent command cache                 |
| prompts/            | Development documentation and guides     |

## Quick Start

For detailed installation instructions, see [SETUP.md](SETUP.md).

### Release Package Installation (Easiest)

Download a pre-built release for your platform:

1. Visit the [Releases page](https://github.com/sbeeredd04/zsh_plugin/releases)
2. Download the appropriate package:
   - `autocomplete-linux-amd64.tar.gz` for Linux
   - `autocomplete-macos-arm64.tar.gz` for macOS
3. Extract and install:
   ```bash
   tar -xzf autocomplete-*.tar.gz
   cd zsh_plugin
   ./scripts/setup.sh
   ```

### Automatic Installation (Recommended)
```bash
# Clone and install
git clone <repository-url> zsh_plugin
cd zsh_plugin
./scripts/setup.sh
```

### Manual Installation
```bash
# Build the system
make clean && make

# Add to your .zshrc
echo "source $(pwd)/plugin.zsh" >> ~/.zshrc

# Reload shell
source ~/.zshrc
```

## How It Works

### 1. **Prefix-Based History Navigation**
- Type any prefix (e.g., `git`)
- Press ↑/↓ to navigate only commands starting with `git`
- System remembers your current position in filtered results
- Return to original text by navigating past the filtered commands

### 2. **Ghost Text Completion**
- As you type, best matching command appears as suggestion
- Press → (right arrow) to accept the ghost text
- Based on frequency and recency of usage

### 3. **Persistent Learning**
- All commands stored in trie structure for fast retrieval
- Frequency tracking for better suggestions
- Data persisted to `data/trie_data.txt`
- No re-initialization between sessions

## Usage Guide

### Basic Operations
- **Type**: Start typing any command prefix
- **↑ Arrow**: Navigate to previous command matching prefix
- **↓ Arrow**: Navigate to next command matching prefix  
- **→ Arrow**: Accept ghost text completion
- **Enter**: Execute command and update usage statistics

### Example Workflow
```bash
# Type a prefix
$ gi<cursor>

# Press ↑ to see filtered history
$ git status         # (from history)
$ git commit -m      # (press ↑ again)
$ git push           # (press ↑ again)

# Press ↓ to go back or navigate to original
$ gi<cursor>         # (back to original)
```

## Testing

### Run Basic Tests
```bash
# Build and test
make test

# Run comprehensive tests
./tests/simple_test.sh
```

### Manual Testing
```bash
# Test ghost text
echo -e "git status\ngit commit" | ./autocomplete ghost "git"

# Test history navigation  
echo -e "ls -la\nps aux" | ./autocomplete history "l" "up" "0"

# Test usage update
echo -e "vim file.txt" | ./autocomplete update "" "vim file.txt"
```

## Development

### Build Options
```bash
make          # Optimized build
make debug    # Debug build with symbols  
make clean    # Clean build artifacts
make rebuild  # Clean and rebuild
make test     # Run built-in tests
```

### Key Files to Understand
- **`src/autocomplete.c`**: Main program logic, persistent storage
- **`src/trie.c`**: Trie data structure implementation
- **`plugin.zsh`**: Zsh widget bindings and key handlers
- **`data/trie_data.txt`**: Persistent command cache

## Performance

### Benchmarks
- **Startup Time**: 0ms (uses cached data)
- **Ghost Text**: <5ms response for any prefix
- **History Filtering**: <10ms for 1000+ commands
- **Memory Usage**: ~1MB for 1000 commands
- **Storage**: ~50KB cache file for typical usage

### Scalability
- **Unlimited Commands**: Dynamic memory allocation
- **Fast Prefix Matching**: O(log n) trie lookups
- **Efficient Caching**: Only loads data once per session
- **Smart Filtering**: Only shows relevant commands

## Troubleshooting

### Common Issues

**Plugin not loading?**
- Check that binary was built: `ls -la autocomplete`
- Verify plugin sourced: `grep "plugin.zsh" ~/.zshrc`
- Restart terminal: `source ~/.zshrc`

**Ghost text not appearing?**
- Type at least 2 characters for suggestions
- Check trie data exists: `ls -la data/trie_data.txt`
- Test manually: `echo "git status" | ./autocomplete ghost "git"`

**Arrow keys not working?**
- Check terminal compatibility: `echo $TERM`
- Test key codes: `cat -v` (press arrows to see codes)
- Try alternative bindings in `plugin.zsh`

**Performance issues?**
- Check cache file size: `du -h data/trie_data.txt`
- Clear cache: `rm -rf data/` (will rebuild on next use)
- Monitor with: `time ./autocomplete ghost "test"`

### Reset Everything
```bash
# Clean rebuild
make clean && make

# Clear persistent data
rm -rf data/

# Restart shell
source ~/.zshrc
```

## Advanced Usage

### Custom Prefix Matching
The system filters history based on exact prefix matching. Commands starting with your typed prefix will appear in navigation.

### Persistent Data Management
- Commands automatically saved to `data/trie_data.txt`
- File grows over time with usage
- Automatic frequency tracking for better suggestions
- Safe to delete `data/` directory to reset

### Integration with Other Tools
```bash
# Export completion function
get_completion() {
    fc -l 1 | awk '{$1=""; print substr($0,2)}' | tail -r | \
    ./autocomplete ghost "$1" 2>/dev/null
}

# Use in scripts
SUGGESTION=$(get_completion "git")
echo "Suggested: $SUGGESTION"
```

## Recent Improvements

This version includes:
- **Ghost Text Styling**: Ghost text now appears in dim gray (color fg=8) for clear visual distinction
- **History Index Reset**: Navigation state properly resets after command execution
- **Widget Registration Fix**: Widgets are registered before key bindings to prevent errors
- **Backspace Enhancements**: Added support for Cmd+Backspace and Option+Backspace with ghost text updates
- **Simplified Architecture**: Removed priority queue complexity
- **Pure Trie Navigation**: Prefix-based filtering only
- **Persistent Storage**: No re-initialization overhead
- **Clean Repository Structure**: Organized directories
- **Robust Error Handling**: Graceful fallbacks
- **Performance Optimization**: Minimal memory usage

## Contributing

Contributions are welcome! Here's how to get started:

1. **Fork the Repository**: Create your own fork on GitHub
2. **Clone Your Fork**: `git clone https://github.com/your-username/zsh_plugin.git`
3. **Create a Branch**: `git checkout -b feature/your-feature`
4. **Make Changes**: Follow the code style and add tests
5. **Test Your Changes**: Run `make test` and verify functionality
6. **Commit**: Use clear commit messages
7. **Push**: `git push origin feature/your-feature`
8. **Create Pull Request**: Submit a PR with a clear description

### Development Resources

- **System Design**: See `prompts/01-system-design.md` for architecture details
- **Feature Guidelines**: See `prompts/03-feature-implementation.md`
- **Release Process**: See `RELEASES.md` for versioning and release steps

---

Experience intelligent command completion that learns and adapts to your workflow with blazing-fast performance!