# Debugging Guide

## Purpose

Systematic approach to identifying, diagnosing, and fixing bugs in the zsh_plugin project.

---

## Table of Contents

1. [Debugging Tools](#debugging-tools)
2. [Common Issues](#common-issues)
3. [Debugging Workflow](#debugging-workflow)
4. [Memory Debugging](#memory-debugging)
5. [Performance Debugging](#performance-debugging)
6. [Zsh-Specific Debugging](#zsh-specific-debugging)

---

## Debugging Tools

### C Code Debugging

#### GDB (GNU Debugger)

**Build with debug symbols**:
```bash
make clean
make debug
```

**Run with GDB**:
```bash
# Start GDB
gdb ./autocomplete

# Set breakpoints
(gdb) break trie_insert
(gdb) break src/autocomplete.c:150

# Run with arguments
(gdb) run ghost "git"

# Step through code
(gdb) step    # Step into functions
(gdb) next    # Step over functions
(gdb) finish  # Run until function returns

# Inspect variables
(gdb) print trie
(gdb) print *node
(gdb) print history_array[0]

# Backtrace
(gdb) backtrace
(gdb) frame 2

# Watchpoints
(gdb) watch history_count
```

#### Valgrind (Memory Debugger)

**Check for memory leaks**:
```bash
valgrind --leak-check=full \
         --show-leak-kinds=all \
         --track-origins=yes \
         --verbose \
         ./autocomplete ghost "git" < history.txt
```

**Common valgrind errors**:
- **Invalid read/write**: Accessing memory out of bounds
- **Conditional jump**: Using uninitialized value
- **Memory leak**: Allocated but not freed
- **Double free**: Freeing same memory twice

#### AddressSanitizer (ASan)

**Build with ASan**:
```bash
gcc -fsanitize=address -g -Iinclude -o autocomplete src/*.c
```

**Run**:
```bash
./autocomplete ghost "git" < history.txt
```

**Advantages**:
- Faster than valgrind
- Detects more types of errors
- Better error messages

### Zsh Code Debugging

#### Enable Zsh Debugging

```bash
# Add to .zshrc temporarily
setopt XTRACE        # Print commands before execution
setopt VERBOSE       # Print input lines as read

# Or run specific function with tracing
zsh -x -c 'source plugin.zsh; accept_ghost_completion'
```

#### Print Debugging

```bash
# In plugin.zsh
self_insert_with_ghost() {
  zle .self-insert
  
  # Debug output to stderr
  echo "[DEBUG] LBUFFER=$LBUFFER" >&2
  echo "[DEBUG] Calling autocomplete" >&2
  
  local full
  full=$("$ZSH_AUTOCOMPLETE_BIN" ghost "$LBUFFER" 2>/dev/null)
  
  echo "[DEBUG] Received: $full" >&2
  # ...
}
```

#### Zsh Log Files

```bash
# Redirect debug output to file
exec 2>/tmp/zsh_debug.log
setopt XTRACE
```

---

## Common Issues

### Issue 1: Ghost Text Not Appearing

**Symptoms**:
- No suggestions shown as you type
- RBUFFER remains empty

**Debugging Steps**:
1. Check if binary exists: `ls -la autocomplete`
2. Test binary manually:
   ```bash
   echo "git status" | ./autocomplete init
   echo "" | ./autocomplete ghost "git"
   ```
3. Check Zsh variables:
   ```bash
   echo $ZSH_GHOST_TEXT
   echo $ZSH_AUTOCOMPLETE_BIN
   ```
4. Enable debug mode in plugin.zsh
5. Check cache file: `cat ~/.cache/zsh-autocomplete/trie_data.txt`

**Common Causes**:
- Binary not built
- Cache file empty/corrupt
- RBUFFER assignment failing
- autocomplete command returning nothing

### Issue 2: Memory Leaks

**Symptoms**:
- Memory usage grows over time
- Valgrind reports leaks

**Debugging Steps**:
1. Run valgrind:
   ```bash
   valgrind --leak-check=full ./autocomplete ghost "test" < /dev/null
   ```
2. Check for missing `free()` calls
3. Verify cleanup_autocomplete() is called
4. Check for early returns that skip cleanup

**Common Causes**:
- Missing `free()` for `malloc()`
- Early returns bypassing cleanup
- Trie nodes not destroyed recursively
- History array entries not freed

### Issue 3: Segmentation Fault

**Symptoms**:
- Crash with "Segmentation fault (core dumped)"

**Debugging Steps**:
1. Enable core dumps:
   ```bash
   ulimit -c unlimited
   ```
2. Run to generate core:
   ```bash
   ./autocomplete ghost "test" < /dev/null
   ```
3. Analyze with gdb:
   ```bash
   gdb ./autocomplete core
   (gdb) backtrace
   (gdb) frame 0
   (gdb) print variable_name
   ```

**Common Causes**:
- NULL pointer dereference
- Array index out of bounds
- Use after free
- Stack overflow (deep recursion)

### Issue 4: Slow Performance

**Symptoms**:
- Noticeable delay when typing
- Commands feel sluggish

**Debugging Steps**:
1. Time operations:
   ```bash
   time echo "" | ./autocomplete ghost "git"
   ```
2. Profile with gprof:
   ```bash
   gcc -pg -Iinclude -o autocomplete src/*.c
   ./autocomplete ghost "git" < history.txt
   gprof autocomplete gmon.out
   ```
3. Check cache file size:
   ```bash
   du -h ~/.cache/zsh-autocomplete/
   ```

**Common Causes**:
- Large cache file (thousands of commands)
- Inefficient algorithm (O(n²) instead of O(n))
- Too many disk I/O operations
- Blocking on stdin when shouldn't

---

## Debugging Workflow

### Step-by-Step Process

#### 1. Reproduce the Bug

**Goal**: Consistently trigger the bug

**Actions**:
1. Note exact steps to reproduce
2. Test in clean environment
3. Identify minimum reproduction case
4. Document environment (OS, shell version, etc.)

**Example**:
```bash
# Minimal reproduction
make clean && make
echo "test command" | ./autocomplete init
./autocomplete ghost "tes"  # Should return "test command"
```

#### 2. Isolate the Problem

**Goal**: Narrow down where bug occurs

**Binary Search Approach**:
1. Is it in C or Zsh layer?
   - Test C binary directly
   - Check Zsh widget behavior separately
2. Which function is problematic?
   - Add print statements at function entry/exit
   - Use gdb breakpoints
3. Which line is problematic?
   - Step through with debugger
   - Add more granular logging

**Example**:
```c
// Add debug prints
void trie_insert(Trie* trie, const char* command) {
    fprintf(stderr, "[DEBUG] trie_insert called with: %s\n", command);
    
    if (!trie || !command) {
        fprintf(stderr, "[DEBUG] trie_insert: invalid input\n");
        return;
    }
    
    // ... rest of function
    fprintf(stderr, "[DEBUG] trie_insert: completed successfully\n");
}
```

#### 3. Understand the Root Cause

**Goal**: Identify why bug happens

**Questions to Ask**:
- What assumption was violated?
- What edge case wasn't handled?
- What invariant was broken?
- What memory was incorrectly managed?

**Example Analysis**:
```
Bug: Segfault in trie_get_best_completion()
Line: current = current->children[index];
Cause: index = 255 (out of bounds for children[128])
Root: No validation of ASCII range before indexing
Fix: Add bounds check: if (index >= ALPHABET_SIZE) continue;
```

#### 4. Implement Fix

**Goal**: Fix the bug without introducing new ones

**Best Practices**:
- Fix root cause, not symptoms
- Add validation/error handling
- Consider edge cases
- Don't change unrelated code

**Example Fix**:
```c
// Before (buggy)
unsigned char index = (unsigned char)command[i];
current = current->children[index];

// After (fixed)
unsigned char index = (unsigned char)command[i];
if (index >= ALPHABET_SIZE) {
    fprintf(stderr, "Warning: Invalid character in command: %d\n", index);
    continue;
}
if (!current->children[index]) {
    return NULL;  // Path doesn't exist
}
current = current->children[index];
```

#### 5. Verify Fix

**Goal**: Ensure bug is fixed and no regressions

**Verification Steps**:
1. Test original reproduction case
2. Test edge cases
3. Run full test suite
4. Run valgrind (no new leaks)
5. Performance regression test

**Example**:
```bash
# Test fix
make clean && make
./autocomplete ghost "test_with_unicode_™" < /dev/null  # Should not crash

# Test suite
make test

# Valgrind
valgrind ./autocomplete ghost "test" < history.txt

# Performance
time ./autocomplete ghost "git" < large_history.txt
```

#### 6. Document Fix

**Goal**: Help future developers understand the fix

**What to Document**:
- Bug description
- Root cause analysis
- Fix explanation
- Test cases added

**Example Commit Message**:
```
fix(trie): handle non-ASCII characters gracefully

Bug: Segfault when command contains characters > 127
Root Cause: No bounds checking on children array index
Fix: Skip invalid characters with warning message

Test: Added test_unicode_handling()
```

---

## Memory Debugging

### Common Memory Issues

#### Issue: Memory Leak

**Detection**:
```bash
valgrind --leak-check=full ./autocomplete ghost "test" < /dev/null
```

**Output**:
```
==12345== LEAK SUMMARY:
==12345==    definitely lost: 1,024 bytes in 1 blocks
==12345==    indirectly lost: 0 bytes in 0 blocks
```

**Fix Pattern**:
```c
// Before
char* result = malloc(100);
if (some_error) {
    return NULL;  // LEAK!
}
free(result);

// After
char* result = malloc(100);
if (some_error) {
    free(result);  // Clean up before return
    return NULL;
}
free(result);
```

#### Issue: Use After Free

**Detection**:
```bash
gcc -fsanitize=address -g -o autocomplete src/*.c
./autocomplete ghost "test" < /dev/null
```

**Output**:
```
==12345==ERROR: AddressSanitizer: heap-use-after-free
```

**Fix Pattern**:
```c
// Before
free(node);
if (node->data) { ... }  // ERROR!

// After
if (node->data) { ... }
free(node);
node = NULL;  // Prevent accidental reuse
```

#### Issue: Double Free

**Detection**:
```bash
valgrind ./autocomplete ghost "test" < /dev/null
```

**Output**:
```
==12345== Invalid free() / delete / delete[] / realloc()
```

**Fix Pattern**:
```c
// Before
free(ptr);
// ... later ...
free(ptr);  // ERROR!

// After
free(ptr);
ptr = NULL;  // Set to NULL after free
// ... later ...
free(ptr);  // Safe (free(NULL) is a no-op)
```

### Memory Debugging Checklist

- [ ] Every `malloc()` has a corresponding `free()`
- [ ] No use-after-free (access after `free()`)
- [ ] No double-free (two `free()` calls)
- [ ] Set pointers to NULL after `free()`
- [ ] Check `malloc()` return value (could be NULL)
- [ ] Free in reverse order of allocation for complex structures
- [ ] Call cleanup function before all exit points

---

## Performance Debugging

### Profiling with gprof

**Build with profiling**:
```bash
gcc -pg -O2 -Iinclude -o autocomplete src/*.c
```

**Run and generate profile**:
```bash
./autocomplete ghost "git" < large_history.txt
gprof autocomplete gmon.out > profile.txt
```

**Analyze output**:
```
Flat profile:

Each sample counts as 0.01 seconds.
  %   cumulative   self              self     total           
 time   seconds   seconds    calls  ms/call  ms/call  name    
 33.33      0.10     0.10   100000     0.00     0.00  trie_insert
 33.33      0.20     0.10     1000     0.10     0.20  filter_history_by_prefix
 20.00      0.26     0.06        1    60.00   300.00  load_history_from_stdin
```

**Interpretation**:
- `trie_insert` uses 33% of total time
- `filter_history_by_prefix` called 1000 times
- Focus optimization on top functions

### Performance Benchmarking

**Create benchmark script**:
```bash
#!/bin/bash
# benchmark.sh

# Generate test data
seq 1 10000 | xargs -I{} echo "command_{}" > test_history.txt

# Benchmark initialization
echo "Testing init..."
time ./autocomplete init < test_history.txt > /dev/null

# Benchmark ghost text
echo "Testing ghost text..."
time for i in {1..1000}; do
    ./autocomplete ghost "command_1" < /dev/null
done

# Benchmark history filtering
echo "Testing history filter..."
time for i in {1..1000}; do
    ./autocomplete history "command_" "up" "0" < /dev/null
done
```

### Performance Optimization Tips

1. **Algorithmic**: Use better algorithm (O(n) → O(log n))
2. **Caching**: Store computed results
3. **Lazy Evaluation**: Compute only when needed
4. **Batching**: Group operations together
5. **Data Structures**: Use appropriate structure for access pattern

---

## Zsh-Specific Debugging

### Widget Debugging

**Test widget in isolation**:
```bash
# In zsh session
autoload -Uz colors && colors

# Define widget
accept_ghost() {
    echo "LBUFFER: $LBUFFER"
    echo "RBUFFER: $RBUFFER"
    echo "GHOST: $ZSH_GHOST_TEXT"
}

# Register and bind
zle -N accept_ghost
bindkey '\e[C' accept_ghost

# Test by typing and pressing right arrow
```

### Key Binding Debugging

**Check what key sends**:
```bash
# In terminal, type this then press your key
cat -v
# Example output for right arrow: ^[[C
```

**List all bindings**:
```bash
bindkey | grep autocomplete
```

### Variable Scope Issues

```bash
# Global vs local
test_scope() {
    VAR="global"  # Global
    local var="local"  # Local to function
    
    echo $VAR    # "global"
    echo $var    # "local"
}

test_scope
echo $VAR  # "global"
echo $var  # (empty - local was destroyed)
```

---

## Conclusion

Effective debugging requires:
- **Systematic approach**: Reproduce, isolate, understand, fix, verify
- **Right tools**: gdb, valgrind, profilers
- **Attention to detail**: Memory management, edge cases
- **Documentation**: Help future you and others

When stuck:
1. Take a break
2. Explain the problem out loud (rubber duck debugging)
3. Ask for help (with reproduction steps and diagnostics)
4. Search similar issues in other projects
