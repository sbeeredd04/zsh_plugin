# VS Code Debugging Guide for Zsh Autocomplete Plugin

This guide shows you how to debug the C program using VS Code's built-in debugger to inspect data flow, variables, and function behavior.

## Prerequisites

1. **VS Code with C/C++ Extension**: Install the Microsoft C/C++ extension
2. **LLDB Debugger**: Already available on macOS
3. **Debug Build**: Use `make debug` to compile with debug symbols

## Quick Start Debugging

### 1. Open the Project in VS Code
```bash
code .  # Open current directory in VS Code
```

### 2. Build Debug Version
```bash
make debug
```

### 3. Start Debugging
- Press `F5` or go to **Run → Start Debugging**
- Choose **"Debug Autocomplete"** configuration
- The debugger will build and launch the program automatically

## Debugging Configurations

We've set up two debugging configurations:

### Configuration 1: "Debug Autocomplete"
- **Args**: `["test command", "up"]`
- **Purpose**: Basic debugging with simple arguments
- **Use**: General debugging and stepping through code

### Configuration 2: "Debug with History Input" 
- **Args**: `["git status", "up"]`
- **Purpose**: Debug with more realistic input
- **Use**: Testing with actual command scenarios

## Setting Breakpoints

### Method 1: Click in Gutter
1. Open `autocomplete.c`
2. Click in the left gutter next to line numbers
3. Red dots indicate active breakpoints

### Method 2: Keyboard Shortcut
1. Place cursor on desired line
2. Press `F9` to toggle breakpoint

### Recommended Breakpoints

```c
// Line ~30: Start of load_history_from_stdin function
int load_history_from_stdin(const char *current_buffer) {

// Line ~65: Inside the getline loop  
while ((read = getline(&line, &len, stdin)) != -1) {

// Line ~90: Start of main function
int main(int argc, char *argv[]) {

// Line ~110: Navigation logic
if (strcmp(direction, "up") == 0) {

// Line ~118: Before returning result
printf("%s|%d", history_entries[current_index], current_index);
```

## Debugging with Input Data

### Method 1: Simulate History Input
1. Create a test file with sample history:
```bash
cat > test_history.txt << EOF
ls -la
git status
make clean
history
EOF
```

2. Modify launch.json temporarily:
```json
"program": "${workspaceFolder}/autocomplete",
"args": ["git commit", "up", "0"],
"console": "integratedTerminal"
```

3. Run with input:
```bash
cat test_history.txt | ./autocomplete "git commit" "up" "0"
```

### Method 2: Use VS Code Integrated Terminal
1. Start debugging
2. In the integrated terminal, paste your test input
3. Press Ctrl+D to send EOF

## Inspecting Variables

### During Debugging Session:

1. **Variables Panel**: Left sidebar shows all local variables
2. **Watch Panel**: Add specific expressions to monitor
3. **Call Stack**: See function call hierarchy
4. **Debug Console**: Execute commands while paused

### Key Variables to Monitor:

```c
// In load_history_from_stdin():
- history_entries     // Array of command strings
- count              // Number of entries loaded
- capacity           // Current array capacity
- line               // Current line being read

// In main():
- argc, argv         // Command line arguments
- current_buffer     // What user typed
- direction          // "up" or "down"
- current_index      // Navigation position
- total_history_entries // Total loaded entries
```

### Watch Expressions
Add these to the Watch panel:
```c
history_entries[0]        // Original user input
history_entries[current_index]  // Currently selected entry
total_history_entries     // Total count
current_index            // Current position
```

## Step-by-Step Debugging

### Navigation Commands:
- **F10**: Step Over (next line, don't enter functions)
- **F11**: Step Into (enter function calls)
- **Shift+F11**: Step Out (exit current function)
- **F5**: Continue (run until next breakpoint)

### Debugging Session Example:

1. **Set breakpoint** at `load_history_from_stdin` entry
2. **Start debugging** (F5)
3. **Inspect arguments** - check `current_buffer` value
4. **Step through** the history loading loop (F10)
5. **Watch** `history_entries` array grow
6. **Continue** to main navigation logic
7. **Inspect** final result before `printf`

## Advanced Debugging Techniques

### 1. Memory Inspection
```c
// In debug console, inspect memory:
-exec memory read --size 8 --format x --count 4 history_entries
```

### 2. Conditional Breakpoints
- Right-click breakpoint → Edit Breakpoint
- Add condition: `count > 5` or `strcmp(line, "git") == 0`

### 3. Debug with Real History
```bash
# Use actual zsh history as input
fc -l 1 | awk '{$1=""; print substr($0,2)}' | tail -r | head -20 > real_history.txt
```

## Troubleshooting Debug Issues

### Issue: Debugger Won't Start
**Solution**: 
```bash
# Install lldb if missing
xcode-select --install

# Check if lldb is available
which lldb
```

### Issue: No Debug Symbols
**Solution**:
```bash
# Ensure debug build
make clean && make debug

# Verify debug symbols
file autocomplete  # Should show "with debug_info"
```

### Issue: Breakpoints Not Hit
**Solution**:
- Ensure you're using debug build (`make debug`)
- Check that breakpoints are on executable lines
- Verify program is actually reaching that code path

## Testing Navigation Logic

### Test Sequence:
1. Set breakpoint at navigation logic
2. Run with: `args: ["original text", "up", "0"]`
3. Step through and verify:
   - `current_index` changes from 0 to 1
   - `history_entries[1]` contains expected command
4. Test down navigation:
   - Change args to `["text", "down", "1"]`
   - Verify `current_index` changes from 1 to 0
   - Confirm `history_entries[0]` is original text

## Performance Profiling

### Monitor Memory Usage:
```c
// Add temporary debug code:
printf("Allocated %d entries, using ~%zu bytes\n", 
       count, count * sizeof(char*) + total_string_memory);
```

### Monitor Execution Time:
```c
#include <time.h>
clock_t start = clock();
// ... code to measure ...
clock_t end = clock();
printf("Execution time: %f seconds\n", 
       ((double)(end - start)) / CLOCKS_PER_SEC);
```

---

## Quick Debug Checklist

✅ Built with `make debug`  
✅ Breakpoints set at key locations  
✅ Watch expressions configured  
✅ Test input data prepared  
✅ VS Code C++ extension installed  

**Happy debugging! 🐛🔍** 