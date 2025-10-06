# Feature Implementation Guide

## Purpose

This guide provides a systematic approach to implementing new features in the zsh_plugin project while maintaining code quality, performance, and architectural consistency.

---

## Table of Contents

1. [Feature Planning](#feature-planning)
2. [Implementation Workflow](#implementation-workflow)
3. [Code Organization](#code-organization)
4. [Testing Requirements](#testing-requirements)
5. [Documentation Requirements](#documentation-requirements)
6. [Performance Considerations](#performance-considerations)
7. [Example: Implementing Fuzzy Matching](#example-implementing-fuzzy-matching)

---

## Feature Planning

### Step 1: Requirement Analysis

**Questions to Answer**:
1. What problem does this feature solve?
2. Who is the target user?
3. What is the expected behavior?
4. What are the edge cases?
5. How does it integrate with existing features?

**Output**: Feature specification document

### Step 2: Design Phase

**Considerations**:
- **Architecture Impact**: Does this require new data structures?
- **Performance Impact**: What is the time/space complexity?
- **API Design**: What functions need to be exposed?
- **Backward Compatibility**: Will this break existing behavior?

**Output**: Technical design document

### Step 3: Break Down into Tasks

**Task Template**:
```markdown
## Feature: [Feature Name]

### Subtasks
1. [ ] Design data structures
2. [ ] Implement core algorithm in C
3. [ ] Add Zsh integration
4. [ ] Write unit tests
5. [ ] Write integration tests
6. [ ] Update documentation
7. [ ] Performance testing
```

---

## Implementation Workflow

### 1. Create Feature Branch

```bash
# Create branch from dev
git checkout dev
git pull origin dev
git checkout -b feature/fuzzy-matching

# Branch naming convention:
# feature/  - new features
# bugfix/   - bug fixes
# refactor/ - code refactoring
# docs/     - documentation only
```

### 2. Implement in Layers

**Layer 1: Data Structures (if needed)**
```c
// In include/fuzzy.h
typedef struct {
    char* query;
    char* target;
    int score;
} FuzzyMatch;
```

**Layer 2: Core Algorithm**
```c
// In src/fuzzy.c
int fuzzy_match_score(const char* query, const char* target) {
    // Implementation
}
```

**Layer 3: Integration with Existing Code**
```c
// In src/autocomplete.c
char* get_ghost_text_fuzzy(const char* prefix) {
    // Use fuzzy matching instead of prefix matching
}
```

**Layer 4: Zsh Integration**
```bash
# In plugin.zsh
fuzzy_ghost_completion() {
    # Call C binary with fuzzy flag
}
```

### 3. Incremental Commits

**Commit Message Format**:
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**: feat, fix, docs, style, refactor, test, chore

**Example**:
```
feat(fuzzy): implement Levenshtein distance algorithm

- Add fuzzy_match_score() function
- Support up to 3 character edits
- Optimize for common prefixes

Closes #42
```

### 4. Self-Review Checklist

Before requesting review:
- [ ] Code compiles without warnings
- [ ] All tests pass
- [ ] No memory leaks (run valgrind)
- [ ] Code follows style guidelines
- [ ] Functions documented
- [ ] README updated (if needed)
- [ ] Performance benchmarks run

---

## Code Organization

### File Structure Guidelines

**When to create a new file**:
- Feature is >500 lines
- Feature is logically independent
- Feature might be reused elsewhere

**File naming conventions**:
```
include/
  feature_name.h      # Public interface
src/
  feature_name.c      # Implementation
tests/
  test_feature_name.sh # Feature tests
```

### Function Organization

**Order in C files**:
```c
// 1. Includes
#include <system_headers.h>
#include "project_headers.h"

// 2. Constants and Macros
#define MAX_SIZE 100

// 3. Type Definitions
typedef struct { ... } MyType;

// 4. Static (private) function declarations
static int helper_function(int x);

// 5. Public function implementations
int public_function(int x) { ... }

// 6. Static function implementations
static int helper_function(int x) { ... }
```

### Naming Conventions

**C Code**:
```c
// Functions: lowercase_with_underscores
int trie_insert(Trie* trie, const char* command);

// Types: PascalCase
typedef struct TrieNode { ... } TrieNode;

// Constants: UPPER_CASE
#define MAX_COMMAND_LENGTH 1024

// Static functions: lowercase_with_underscores
static void helper_function(void);

// Global variables: lowercase_with_prefix
static Trie* command_trie = NULL;
```

**Zsh Code**:
```bash
# Functions: lowercase_with_underscores
accept_ghost_completion() { ... }

# Variables: UPPER_CASE for globals, lowercase for locals
ZSH_GHOST_TEXT=""
local result
```

---

## Testing Requirements

### Unit Tests

**Requirements**:
- Test each function independently
- Cover normal cases, edge cases, and error cases
- Use assertions for validation

**Example**:
```c
// tests/test_trie.c
void test_trie_insert() {
    Trie* trie = trie_create();
    assert(trie != NULL);
    
    trie_insert(trie, "test");
    assert(trie_search(trie, "test") == true);
    assert(trie_search(trie, "other") == false);
    
    trie_destroy(trie);
}
```

### Integration Tests

**Requirements**:
- Test component interactions
- Use realistic data
- Verify end-to-end workflows

**Example**:
```bash
# tests/test_integration.sh
test_ghost_completion() {
    echo "git status" | ./autocomplete init
    result=$(echo "" | ./autocomplete ghost "git st")
    [ "$result" = "git status" ] || fail "Ghost completion failed"
}
```

### Performance Tests

**Requirements**:
- Measure execution time
- Test with large datasets
- Compare against benchmarks

**Example**:
```bash
# Benchmark with 10,000 commands
time {
    seq 1 10000 | xargs -I{} echo "cmd_{}" | ./autocomplete init
    echo "" | ./autocomplete ghost "cmd_"
}
```

---

## Documentation Requirements

### Code Documentation

**Function Documentation Template**:
```c
/**
 * Brief description of what the function does.
 *
 * Detailed description if needed, including:
 * - Algorithm explanation
 * - Special considerations
 * - Side effects
 *
 * @param param1    Description of first parameter
 * @param param2    Description of second parameter
 * @return          Description of return value
 *
 * @note   Any important notes
 * @warning Any warnings about usage
 *
 * Example:
 * @code
 * Trie* trie = trie_create();
 * trie_insert(trie, "example");
 * @endcode
 */
int example_function(int param1, char* param2);
```

**Inline Comments**:
```c
// ✅ Good: Explain WHY, not WHAT
// Use stack-based DFS to avoid recursion depth limits
stack[stack_top++] = node;

// ❌ Bad: Redundant with code
// Increment stack_top
stack_top++;
```

### README Updates

**When to update README**:
- New user-facing feature
- Changed installation process
- New command-line arguments
- Changed key bindings

**Sections to update**:
- Features list
- Usage examples
- Configuration options
- Troubleshooting

---

## Performance Considerations

### Algorithm Selection

**Guidelines**:
1. Start with simple, correct implementation
2. Profile to find bottlenecks
3. Optimize hot paths only
4. Document time/space complexity

**Example Analysis**:
```
Linear scan:     O(n)     - Use for n < 100
Binary search:   O(log n) - Use for sorted data
Hash table:      O(1)     - Use for exact matching
Trie:           O(k)     - Use for prefix matching
```

### Memory Optimization

**Strategies**:
- Reuse allocations where possible
- Free memory as soon as not needed
- Use stack allocation for small, fixed-size data
- Pool allocations for many same-sized objects

**Example**:
```c
// ❌ Bad: Repeated allocations
for (int i = 0; i < 1000; i++) {
    char* temp = malloc(100);
    process(temp);
    free(temp);
}

// ✅ Good: Single allocation
char* temp = malloc(100);
for (int i = 0; i < 1000; i++) {
    process(temp);
}
free(temp);
```

### I/O Optimization

**Guidelines**:
- Minimize file operations
- Use buffered I/O
- Batch writes when possible
- Async I/O for non-critical paths

**Example**:
```c
// ❌ Bad: One write per command
for (int i = 0; i < count; i++) {
    fprintf(f, "%s\n", commands[i]);
    fflush(f);  // Forces disk write
}

// ✅ Good: Buffered writes
for (int i = 0; i < count; i++) {
    fprintf(f, "%s\n", commands[i]);
}
fflush(f);  // Single disk write at end
```

---

## Example: Implementing Fuzzy Matching

### Feature Specification

**Goal**: Allow approximate matching for command completion

**Behavior**:
- User types "gt sttus"
- System suggests "git status" (2 character edits)
- Only suggest if edit distance ≤ 3

### Design

**Algorithm**: Levenshtein distance (dynamic programming)

**Time Complexity**: O(n × m) where n, m are string lengths

**Integration Point**: Replace `trie_get_best_completion()` or add new function

### Implementation

#### Step 1: Add Fuzzy Matching Function

```c
// include/fuzzy.h
#ifndef FUZZY_H
#define FUZZY_H

/**
 * Calculate Levenshtein distance between two strings.
 *
 * @param s1    First string
 * @param s2    Second string
 * @return      Edit distance (number of insertions, deletions, substitutions)
 */
int levenshtein_distance(const char* s1, const char* s2);

/**
 * Get best fuzzy match for a query string.
 *
 * @param trie      Trie containing commands
 * @param query     User's input query
 * @param max_dist  Maximum edit distance allowed
 * @return          Best matching command, or NULL
 */
char* fuzzy_get_best_match(Trie* trie, const char* query, int max_dist);

#endif // FUZZY_H
```

```c
// src/fuzzy.c
#include "fuzzy.h"
#include "trie.h"
#include <stdlib.h>
#include <string.h>

int levenshtein_distance(const char* s1, const char* s2) {
    int len1 = strlen(s1);
    int len2 = strlen(s2);
    
    // Create DP table
    int** dp = malloc((len1 + 1) * sizeof(int*));
    for (int i = 0; i <= len1; i++) {
        dp[i] = malloc((len2 + 1) * sizeof(int));
    }
    
    // Initialize base cases
    for (int i = 0; i <= len1; i++) dp[i][0] = i;
    for (int j = 0; j <= len2; j++) dp[0][j] = j;
    
    // Fill DP table
    for (int i = 1; i <= len1; i++) {
        for (int j = 1; j <= len2; j++) {
            if (s1[i-1] == s2[j-1]) {
                dp[i][j] = dp[i-1][j-1];
            } else {
                int insert = dp[i][j-1] + 1;
                int delete = dp[i-1][j] + 1;
                int replace = dp[i-1][j-1] + 1;
                dp[i][j] = (insert < delete) ? 
                          ((insert < replace) ? insert : replace) :
                          ((delete < replace) ? delete : replace);
            }
        }
    }
    
    int result = dp[len1][len2];
    
    // Free DP table
    for (int i = 0; i <= len1; i++) {
        free(dp[i]);
    }
    free(dp);
    
    return result;
}

char* fuzzy_get_best_match(Trie* trie, const char* query, int max_dist) {
    // TODO: Traverse trie, calculate distance for each command,
    // return command with minimum distance ≤ max_dist
    return NULL;
}
```

#### Step 2: Integrate with Autocomplete

```c
// In src/autocomplete.c
#include "fuzzy.h"

// Add new command-line option
if (strcmp(operation, "fuzzy") == 0) {
    result = fuzzy_get_best_match(command_trie, current_buffer, 3);
    if (result) {
        printf("%s", result);
        free(result);
    }
}
```

#### Step 3: Update Zsh Plugin

```bash
# In plugin.zsh

# Add configuration variable
typeset -g ZSH_FUZZY_ENABLED=1

# Modify ghost text function
self_insert_with_ghost() {
  zle .self-insert
  local full
  if (( ZSH_FUZZY_ENABLED )); then
    full=$("$ZSH_AUTOCOMPLETE_BIN" fuzzy "$LBUFFER" 2>/dev/null) || full=""
  else
    full=$("$ZSH_AUTOCOMPLETE_BIN" ghost "$LBUFFER" 2>/dev/null) || full=""
  fi
  # ... rest of function
}
```

#### Step 4: Add Tests

```bash
# tests/test_fuzzy.sh
#!/bin/bash

test_fuzzy_matching() {
    echo "git status" | ./autocomplete init
    
    # Exact match
    result=$(./autocomplete fuzzy "git status")
    [ "$result" = "git status" ] || fail "Exact match failed"
    
    # One character off
    result=$(./autocomplete fuzzy "git statu")
    [ "$result" = "git status" ] || fail "One char edit failed"
    
    # Two characters off
    result=$(./autocomplete fuzzy "git sttus")
    [ "$result" = "git status" ] || fail "Two char edit failed"
    
    # Too far off (should return nothing)
    result=$(./autocomplete fuzzy "xyz")
    [ -z "$result" ] || fail "Should not match distant strings"
}
```

#### Step 5: Update Documentation

```markdown
# In README.md

## ✨ Features

- 🔍 **Fuzzy Matching**: Find commands even with typos (up to 3 characters)
  - Type "gt sttus" → suggests "git status"
  - Configurable edit distance threshold
  - Optional feature (can be disabled)

## Configuration

Add to your `.zshrc`:

```bash
# Enable/disable fuzzy matching (default: enabled)
ZSH_FUZZY_ENABLED=1

# Maximum edit distance for fuzzy matching (default: 3)
ZSH_FUZZY_MAX_DISTANCE=3
```
```

#### Step 6: Performance Testing

```bash
# Benchmark fuzzy matching
time {
    echo "git status" | ./autocomplete init
    for i in {1..1000}; do
        ./autocomplete fuzzy "git sttus" > /dev/null
    done
}
```

#### Step 7: Create PR

```markdown
## Pull Request: Add Fuzzy Matching Feature

### Description
Implements approximate string matching for command completion using Levenshtein distance algorithm.

### Features
- Levenshtein distance calculation
- Configurable max edit distance
- Zsh integration with enable/disable flag
- Comprehensive tests

### Performance
- Edit distance: O(n×m) time, O(n×m) space
- Typical case: <10ms for 1000 commands
- Memory: +2KB per query (DP table)

### Testing
- Unit tests for levenshtein_distance()
- Integration tests for fuzzy matching
- Performance benchmarks included

### Documentation
- Function documentation added
- README updated with usage examples
- Configuration options documented
```

---

## Conclusion

This guide provides a framework for:
- Planning features systematically
- Implementing with quality and consistency
- Testing comprehensively
- Documenting thoroughly
- Ensuring performance

Follow these guidelines to maintain code quality and project cohesion while adding new capabilities.
