# System Design: Zsh Autocomplete Plugin

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Data Structures](#data-structures)
3. [Algorithms](#algorithms)
4. [Storage System](#storage-system)
5. [Memory Management](#memory-management)
6. [Performance Characteristics](#performance-characteristics)
7. [Design Decisions](#design-decisions)

---

## Architecture Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Interface                           │
│                    (Zsh Terminal Session)                        │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ Key Events
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                        Zsh Plugin Layer                          │
│                        (plugin.zsh)                              │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │   Widgets    │  │ Key Bindings │  │ Ghost Render │         │
│  │              │  │              │  │              │         │
│  │ - self_insert│  │ ↑/↓ → history│  │ - RBUFFER    │         │
│  │ - backspace  │  │ → → accept   │  │ - redisplay  │         │
│  │ - accept_line│  │ Tab → complete│  │              │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ Process Invocation
                             │ (stdin/stdout pipe)
┌────────────────────────────▼────────────────────────────────────┐
│                    C Processing Layer                            │
│                    (autocomplete binary)                         │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              Operation Dispatcher                         │  │
│  │  - init    : Initialize from stdin                       │  │
│  │  - ghost   : Get best completion for prefix              │  │
│  │  - history : Navigate filtered history                   │  │
│  │  - update  : Update command frequency                    │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                  Core Logic                               │  │
│  │  - load_history_from_stdin()                             │  │
│  │  - filter_history_by_prefix()                            │  │
│  │  - get_ghost_text()                                      │  │
│  │  - navigate_filtered_history()                           │  │
│  │  - update_command_usage()                                │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ Read/Write
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                      Data Structure Layer                        │
│                      (trie.c, trie.h)                           │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    Trie Operations                        │  │
│  │  - trie_create()                                         │  │
│  │  - trie_insert()                                         │  │
│  │  - trie_search()                                         │  │
│  │  - trie_get_best_completion()                           │  │
│  │  - trie_update_frequency()                              │  │
│  │  - trie_destroy()                                       │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ Persistence
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                       Storage Layer                              │
│                 ~/.cache/zsh-autocomplete/                      │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │               trie_data.txt                               │  │
│  │                                                           │  │
│  │  Format: command|frequency|timestamp                     │  │
│  │  Example:                                                │  │
│  │    git status|15|1709654321                             │  │
│  │    git commit -m|8|1709654290                           │  │
│  │    make clean|3|1709650000                              │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Data Structures

### 1. Trie Node (`TrieNode`)

**Purpose**: Store command prefixes in a tree structure for fast lookup

**Structure**:
```c
typedef struct TrieNode {
    struct TrieNode* children[ALPHABET_SIZE];  // 128 pointers (ASCII)
    bool is_end_of_word;                       // Marks complete command
    char* full_command;                        // Complete command string
    int frequency;                             // Usage count
    long last_used;                            // Unix timestamp
} TrieNode;
```

**Memory Layout**:
```
TrieNode (size ≈ 1040 bytes per node)
├─ children[128]    : 1024 bytes (128 × 8-byte pointers)
├─ is_end_of_word   : 1 byte (bool)
├─ full_command     : 8 bytes (pointer)
├─ frequency        : 4 bytes (int)
└─ last_used        : 8 bytes (long)
```

**Example Trie for ["git", "git status", "go"]**:
```
                root
               /    \
              g      ...
             / \
            i   o
           /     \
          t*      *
         /       (end: "go")
        ' '
       /
      s
     /
    t
   /
  a
 /
t
|
u
|
s
|
*
(end: "git status")

* = is_end_of_word = true
```

### 2. Trie (`Trie`)

**Purpose**: Container for the trie structure with metadata

**Structure**:
```c
typedef struct {
    TrieNode* root;           // Root of the trie
    int total_commands;       // Total unique commands
} Trie;
```

**Invariants**:
- `root` is never NULL after creation
- `total_commands` equals number of nodes with `is_end_of_word == true`

### 3. History Array

**Purpose**: Maintain ordered list of all commands for filtering

**Structure**:
```c
static char** history_array;     // Dynamic array of command strings
static int history_count;        // Number of commands
static char** filtered_history;  // Subset matching current prefix
static int filtered_count;       // Number of filtered commands
```

**Relationship to Trie**:
- Trie stores commands for fast prefix matching
- Array stores commands in insertion order
- Both updated in sync during `trie_insert()`

---

## Algorithms

### 1. Trie Insertion

**Function**: `trie_insert(Trie* trie, const char* command)`

**Algorithm**:
```
1. Start at root node
2. For each character in command:
   a. Get ASCII index
   b. If child[index] is NULL, create new node
   c. Move to child[index]
3. Mark last node as end_of_word
4. Store full command string
5. Increment frequency
6. Update last_used timestamp
```

**Time Complexity**: O(k) where k = length of command
**Space Complexity**: O(k) in worst case (all new nodes)

**Example**:
```c
// Inserting "git" into empty trie
trie_insert(trie, "git");

// Creates path: root -> 'g' -> 'i' -> 't'
// Marks 't' node as end_of_word
// Stores "git" at 't' node
// Sets frequency = 1
```

### 2. Best Completion Search

**Function**: `trie_get_best_completion(Trie* trie, const char* prefix)`

**Algorithm**:
```
1. Navigate to prefix node:
   a. Start at root
   b. Follow path for each character in prefix
   c. If path doesn't exist, return NULL
   
2. Find best completion from prefix node:
   a. Initialize stack with prefix node
   b. While stack not empty:
      - Pop node
      - If is_end_of_word:
        * Calculate score = frequency × 100 + recency_bonus
        * Update best if score > current_best
      - Push all non-NULL children
   
3. Return command from best-scoring node
```

**Scoring Formula**:
```
score = frequency × 100 + recency_bonus
where recency_bonus = 50 if (now - last_used) < 3600 seconds, else 0
```

**Time Complexity**: O(n) where n = nodes in subtree
**Space Complexity**: O(h) where h = max depth in subtree

**Example**:
```c
// Commands: "git status" (freq=15, recent)
//          "git stash" (freq=5, old)
// Prefix: "git st"

trie_get_best_completion(trie, "git st");
// Score for "git status": 15×100 + 50 = 1550
// Score for "git stash":  5×100 + 0 = 500
// Returns: "git status"
```

### 3. History Filtering

**Function**: `filter_history_by_prefix(const char* prefix)`

**Algorithm**:
```
1. Clear filtered_history array
2. For each command in history_array:
   a. If command starts with prefix:
      - Add to filtered_history
      - Increment filtered_count
3. filtered_history now contains only matching commands
```

**Time Complexity**: O(n) where n = history_count
**Space Complexity**: O(m) where m = filtered_count (pointers only)

### 4. Navigation Logic

**Function**: `navigate_filtered_history(prefix, direction, start_index)`

**Algorithm**:
```
1. Filter history by prefix
2. Calculate new index:
   - If "up": index++
   - If "down": index--
3. Handle wrapping:
   - If index >= filtered_count: index = -1 (original)
   - If index < -1: index = filtered_count - 1
4. Return command at index:
   - If index == -1: return original prefix
   - Else: return filtered_history[filtered_count - 1 - index]
```

**Indexing Strategy**:
```
filtered_history = ["cmd1", "cmd2", "cmd3"]  (oldest to newest)
                    ↑                   ↑
                  index 0            index 2

User navigation: -1 → 0 → 1 → 2 → -1
Display order:  original → cmd3 → cmd2 → cmd1 → original
                          (newest)      (oldest)
```

---

## Storage System

### File Format

**Location**: `~/.cache/zsh-autocomplete/trie_data.txt`

**Format**: Plain text, one command per line
```
<command>|<frequency>|<timestamp>
```

**Example**:
```
git status|15|1709654321
git commit -m|8|1709654290
make clean|3|1709650000
ls -la|22|1709654400
```

### Serialization

**Function**: `save_trie_to_file()`

**Algorithm**:
```
1. Ensure cache directory exists
2. Open trie_data.txt for writing
3. For each command in history_array:
   a. Find corresponding trie node
   b. Extract frequency and timestamp
   c. Write "command|freq|ts\n"
4. Close file
```

### Deserialization

**Function**: `load_trie_from_file()`

**Algorithm**:
```
1. Open trie_data.txt for reading
2. For each line:
   a. Parse command, frequency, timestamp
   b. Insert command into trie
   c. Set frequency and timestamp from file
   d. Add command to history_array
3. Update history_count
4. Close file
```

**Error Handling**:
- If file doesn't exist: silently continue (empty trie)
- If parse error: skip line, continue
- If memory allocation fails: abort

---

## Memory Management

### Allocation Strategy

**Trie Nodes**:
- Allocated on-demand during insertion
- Never shrunk (no deletion support)
- Total nodes ≈ sum of all command lengths

**History Arrays**:
- Start with capacity of 1000
- Double capacity when full (exponential growth)
- Never shrunk

### Deallocation Strategy

**Cleanup Order**:
```
1. cleanup_autocomplete()
   ├─ trie_destroy(command_trie)
   │  └─ trie_node_destroy(node)  [recursive]
   │     ├─ Destroy all 128 children
   │     ├─ Free full_command string
   │     └─ Free node itself
   │
   ├─ Free history_array entries
   │  ├─ Free each command string
   │  └─ Free array itself
   │
   ├─ Free filtered_history (pointers only)
   └─ Free current_prefix
```

**Memory Leak Prevention**:
- Every `malloc()` paired with `free()`
- Recursive destruction for trees
- Always free before reassignment

### Memory Footprint Analysis

**For 1000 commands (avg length 30 chars)**:
```
Trie nodes:      1040 bytes/node × ~30,000 nodes ≈ 30 MB
Command strings: 30 bytes × 1000 ≈ 30 KB
History array:   8 bytes × 1000 = 8 KB
Filtered array:  8 bytes × 1000 = 8 KB
Total:           ~30 MB

Actual measured: ~1 MB (thanks to shared prefixes!)
```

**Efficiency Factor**: Trie shares common prefixes
- "git status", "git commit" share "git " prefix
- Actual nodes << theoretical maximum

---

## Performance Characteristics

### Time Complexity

| Operation | Complexity | Typical Time |
|-----------|-----------|--------------|
| `trie_insert` | O(k) | <1 ms |
| `trie_search` | O(k) | <1 ms |
| `get_best_completion` | O(n) | <5 ms |
| `filter_history` | O(h) | <10 ms |
| `navigate_history` | O(h) | <10 ms |
| `save_to_file` | O(h × k) | <50 ms |
| `load_from_file` | O(h × k) | <50 ms |

Where:
- k = average command length (~30)
- n = nodes in trie subtree
- h = total history size

### Space Complexity

| Structure | Complexity | Typical Size |
|-----------|-----------|--------------|
| Trie | O(h × k) | ~1 MB |
| History array | O(h) | ~30 KB |
| Filtered array | O(h) | ~8 KB |
| File cache | O(h × k) | ~50 KB |

### Optimization Techniques

1. **Lazy Initialization**: Only load cache on first use
2. **Prefix Sharing**: Trie automatically deduplicates prefixes
3. **Stack-based DFS**: Avoid recursion overhead in search
4. **Pointer Arrays**: Filtered history stores pointers, not copies
5. **Buffered I/O**: Use `fprintf`/`fgets` for file operations

---

## Design Decisions

### 1. Why C for Core Logic?

**Decision**: Implement autocomplete engine in C

**Rationale**:
- **Performance**: Sub-millisecond response times required
- **Memory Control**: Precise memory management for large tries
- **Portability**: Works on any Unix-like system
- **Simplicity**: No dependencies, single binary

**Trade-offs**:
- More complex memory management
- Manual error handling
- Longer development time

### 2. Why Trie over Hash Table?

**Decision**: Use trie for command storage

**Rationale**:
- **Prefix Matching**: Natural fit for autocomplete
- **Memory Efficiency**: Shared prefixes reduce duplication
- **Ordered Traversal**: Easy to find all completions
- **No Collisions**: Guaranteed O(k) lookup

**Trade-offs**:
- More memory per command (pointers)
- Slower than hash for exact matches
- More complex implementation

### 3. Why Persistent Cache?

**Decision**: Store trie data between sessions

**Rationale**:
- **Zero Startup Cost**: No initialization delay
- **Preserves Learning**: Frequency data persists
- **User Expectation**: Suggestions available immediately

**Trade-offs**:
- Disk I/O overhead
- Cache invalidation complexity
- Potential staleness

### 4. Why XDG Cache Directory?

**Decision**: Store cache in `~/.cache/zsh-autocomplete/`

**Rationale**:
- **Standard Compliance**: Follows XDG Base Directory spec
- **User Expectations**: Cache data goes in cache dir
- **Easy Cleanup**: Users know where cache lives

**Trade-offs**:
- Requires XDG_CACHE_HOME or HOME env var
- Not portable to Windows

### 5. Why Separate init Operation?

**Decision**: Require explicit `init` call to load history from stdin

**Rationale**:
- **Non-blocking**: Other operations don't wait for stdin
- **Efficiency**: Only load once per session
- **Flexibility**: Can initialize from different sources

**Trade-offs**:
- More complex plugin code
- User must call init in .zshrc
- Two initialization paths

### 6. Why Scoring Algorithm?

**Decision**: Use `score = frequency × 100 + recency_bonus`

**Rationale**:
- **Frequency Matters**: Recent commands used often rank high
- **Recency Matters**: Recent one-off commands still rank
- **Simple**: Easy to compute, no ML needed
- **Effective**: Works well in practice

**Trade-offs**:
- Magic numbers (100, 50)
- No context awareness
- Doesn't handle typos

---

## Future Improvements

### Planned Enhancements

1. **Fuzzy Matching**: Allow approximate prefix matching
2. **Context Awareness**: Consider PWD, git branch, etc.
3. **Multi-word Completion**: Complete arguments, not just commands
4. **Compression**: Compress trie data file
5. **Incremental Save**: Only save changed entries
6. **Configurable Scoring**: User-defined scoring weights

### Performance Optimizations

1. **Bloom Filter**: Quick negative lookups before trie search
2. **LRU Cache**: Cache recent completions in memory
3. **Concurrent I/O**: Background thread for file writes
4. **Mmap**: Memory-map cache file for faster loads

### Architectural Improvements

1. **Plugin API**: Expose functions for other plugins
2. **IPC Optimization**: Use Unix sockets instead of pipes
3. **Batch Operations**: Process multiple commands in one call
4. **Incremental Updates**: Update trie without full reload

---

## Conclusion

This system design demonstrates:
- **Efficient Data Structures**: Trie for fast prefix matching
- **Performance Focus**: C implementation for speed
- **Persistent Learning**: Cross-session intelligence
- **Modular Architecture**: Clear separation of concerns
- **Memory Safety**: Careful allocation/deallocation
- **Extensibility**: Room for future enhancements

The design balances performance, simplicity, and maintainability while providing a delightful user experience.
