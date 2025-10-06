# Code Review Checklist

## Purpose

Ensure code quality, maintainability, and consistency through systematic code review.

---

## Quick Checklist

### Before Submitting PR

- [ ] Code compiles without warnings (`make clean && make`)
- [ ] All tests pass (`make test`)
- [ ] No memory leaks (run valgrind)
- [ ] Self-reviewed code changes
- [ ] Added tests for new features
- [ ] Updated documentation
- [ ] Followed coding standards
- [ ] Commits have clear messages

### Reviewer Checklist

- [ ] Code correctness
- [ ] Memory safety
- [ ] Performance implications
- [ ] Test coverage
- [ ] Documentation completeness
- [ ] Code style adherence
- [ ] Security considerations

---

## Detailed Review Areas

### 1. Correctness

**Questions**:
- Does the code do what it's supposed to do?
- Are edge cases handled?
- Are error conditions handled?
- Are assumptions documented?

**Example Review Comments**:

```c
// [NOT DONE] Missing NULL check
char* get_completion(const char* prefix) {
    return trie_get_best_completion(trie, prefix);
}

// 💬 Review comment: "What if trie is NULL? Should we check and return NULL?"

// [DONE] Fixed
char* get_completion(const char* prefix) {
    if (!trie || !prefix) {
        return NULL;
    }
    return trie_get_best_completion(trie, prefix);
}
```

### 2. Memory Safety

**Check For**:
- Proper allocation/deallocation pairing
- No use-after-free
- No double-free
- No buffer overflows
- NULL checks after malloc

**Example Review Comments**:

```c
// [NOT DONE] Potential memory leak
char* result = malloc(100);
if (error) {
    return NULL;  // Memory leak!
}
free(result);

// 💬 Review comment: "Memory leak on error path. Please free before return."

// [DONE] Fixed
char* result = malloc(100);
if (error) {
    free(result);
    return NULL;
}
free(result);
```

### 3. Performance

**Check For**:
- Time complexity of algorithms
- Unnecessary allocations
- Inefficient loops
- Excessive I/O

**Example Review Comments**:

```c
// [NOT DONE] O(n²) complexity
for (int i = 0; i < count; i++) {
    for (int j = 0; j < count; j++) {
        if (array[i] == array[j] && i != j) {
            // Remove duplicates
        }
    }
}

// 💬 Review comment: "This has O(n²) complexity. Consider using a hash table for O(n)."

// [DONE] Fixed with hash table approach
// (implementation omitted for brevity)
```

### 4. Code Style

**Check For**:
- Consistent naming conventions
- Proper indentation
- Appropriate comments
- Function length (<100 lines)
- Clear variable names

**Example Review Comments**:

```c
// [NOT DONE] Poor style
int f(int a,int b){
int c=a+b;
return c;}

// 💬 Review comment: "Please format according to project style (spaces, braces)."

// [DONE] Fixed
int add_numbers(int first, int second) {
    int sum = first + second;
    return sum;
}
```

### 5. Testing

**Check For**:
- Test coverage for new code
- Edge case testing
- Error condition testing
- Integration tests

**Example Review Comments**:

```c
// New function added
int divide(int a, int b) {
    return a / b;
}

// 💬 Review comment: "Please add tests for division by zero."

// [DONE] Test added
void test_divide() {
    assert(divide(10, 2) == 5);
    assert(divide(7, 3) == 2);
    assert(divide(5, 0) == -1);  // Error case
}
```

### 6. Documentation

**Check For**:
- Function documentation
- Complex algorithm explanation
- README updates for user-facing changes
- Changelog updates

**Example Review Comments**:

```c
// [NOT DONE] No documentation
char* get_best_match(Trie* t, const char* p, int d);

// 💬 Review comment: "Please add function documentation explaining parameters."

// [DONE] Fixed
/**
 * Find the best fuzzy match for a query string.
 *
 * @param t    Trie containing commands
 * @param p    Query prefix to match
 * @param d    Maximum edit distance allowed
 * @return     Best matching command, or NULL if none found
 */
char* get_best_match(Trie* t, const char* p, int d);
```

---

## Common Issues and Solutions

### Issue 1: Magic Numbers

**Problem**: Hard-coded values without explanation

```c
// [NOT DONE] Magic number
if (score > 1550) {
    return true;
}

// [DONE] Named constant
#define SCORE_THRESHOLD 1550  // Minimum score for relevance
if (score > SCORE_THRESHOLD) {
    return true;
}
```

### Issue 2: Deep Nesting

**Problem**: Too many nested if/for statements

```c
// [NOT DONE] Too deeply nested (4 levels)
if (a) {
    if (b) {
        for (int i = 0; i < n; i++) {
            if (c[i]) {
                // Do something
            }
        }
    }
}

// [DONE] Early returns reduce nesting
if (!a || !b) return;
for (int i = 0; i < n; i++) {
    if (!c[i]) continue;
    // Do something
}
```

### Issue 3: Long Functions

**Problem**: Functions >100 lines

```c
// [NOT DONE] 200-line function doing everything

// [DONE] Split into smaller functions
void process_command(const char* cmd) {
    validate_command(cmd);
    parse_command(cmd);
    execute_command(cmd);
    log_command(cmd);
}
```

### Issue 4: Poor Error Handling

**Problem**: Ignoring errors or unclear error messages

```c
// [NOT DONE] Silent failure
FILE* f = fopen("file.txt", "r");
char buffer[100];
fgets(buffer, 100, f);  // f could be NULL!

// [DONE] Proper error handling
FILE* f = fopen("file.txt", "r");
if (!f) {
    fprintf(stderr, "Error: Cannot open file.txt: %s\n", strerror(errno));
    return -1;
}
char buffer[100];
if (!fgets(buffer, 100, f)) {
    fprintf(stderr, "Error: Failed to read from file\n");
    fclose(f);
    return -1;
}
fclose(f);
```

### Issue 5: Unclear Variable Names

**Problem**: Single-letter or abbreviated names

```c
// [NOT DONE] Unclear
int n = get_cnt();
for (int i = 0; i < n; i++) {
    process(arr[i]);
}

// [DONE] Clear
int command_count = get_command_count();
for (int i = 0; i < command_count; i++) {
    process_command(commands[i]);
}
```

---

## Review Comments Examples

### Positive Feedback

```
[DONE] "Nice use of const correctness here!"
[DONE] "Good edge case handling."
[DONE] "Clear and concise function - easy to understand."
[DONE] "Excellent documentation!"
```

### Constructive Feedback

```
💬 "Consider adding a NULL check before dereferencing."
💬 "This could be more efficient using a hash table."
💬 "Please add a comment explaining this algorithm."
💬 "Can we extract this into a separate function?"
```

### Critical Issues

```
🚨 "This will cause a buffer overflow with input > 100 chars."
🚨 "Memory leak: allocated but never freed."
🚨 "This breaks backward compatibility - needs discussion."
```

---

## Security Review

### Input Validation

```c
// [DONE] Validate all inputs
void process_command(const char* cmd, size_t max_len) {
    if (!cmd) {
        fprintf(stderr, "Error: NULL command\n");
        return;
    }
    
    size_t len = strlen(cmd);
    if (len == 0 || len > max_len) {
        fprintf(stderr, "Error: Invalid command length\n");
        return;
    }
    
    // Process valid command
}
```

### Buffer Overflow Prevention

```c
// [NOT DONE] Unsafe
char buffer[100];
strcpy(buffer, user_input);  // Potential overflow!

// [DONE] Safe
char buffer[100];
strncpy(buffer, user_input, sizeof(buffer) - 1);
buffer[sizeof(buffer) - 1] = '\0';  // Ensure null termination
```

### Path Traversal Prevention

```bash
# [NOT DONE] Unsafe
cache_file="$user_input/trie_data.txt"

# [DONE] Safe
cache_file="${XDG_CACHE_HOME:-$HOME/.cache}/zsh-autocomplete/trie_data.txt"
# Validate that cache_file doesn't contain ".."
```

---

## Performance Review

### Algorithm Complexity

**Review Questions**:
- What is the time complexity?
- What is the space complexity?
- Can it be optimized?
- Is there a better algorithm?

**Example**:
```
💬 "This linear search is O(n). Since the array is sorted, 
    binary search would be O(log n)."
```

### Memory Efficiency

**Review Questions**:
- Are allocations necessary?
- Can we reuse existing memory?
- Are we allocating the right size?

**Example**:
```c
// [NOT DONE] Inefficient - allocating in loop
for (int i = 0; i < 1000; i++) {
    char* temp = malloc(100);
    process(temp);
    free(temp);
}

// [DONE] Efficient - single allocation
char* temp = malloc(100);
for (int i = 0; i < 1000; i++) {
    process(temp);
}
free(temp);
```

---

## Approval Criteria

### Required for Approval

1. [DONE] **Builds Successfully**
   ```bash
   make clean && make
   # Exit code 0, no errors
   ```

2. [DONE] **Tests Pass**
   ```bash
   make test
   # All tests pass
   ```

3. [DONE] **No Memory Issues**
   ```bash
   valgrind --leak-check=full ./autocomplete ghost "test" < /dev/null
   # No leaks, no errors
   ```

4. [DONE] **Code Quality**
   - Follows style guidelines
   - Appropriate comments
   - Clear function/variable names

5. [DONE] **Documentation**
   - Function documentation added
   - README updated (if needed)
   - Changelog updated

### Nice to Have

- Performance benchmarks
- Additional test coverage
- Refactoring of related code
- Improved error messages

---

## Review Process

### For Authors

1. **Self-Review First**
   - Read your own diff
   - Check for obvious issues
   - Verify tests pass

2. **Provide Context**
   - Clear PR description
   - Link to related issues
   - Explain design decisions

3. **Be Responsive**
   - Address review comments promptly
   - Ask for clarification if needed
   - Mark resolved conversations

4. **Iterate**
   - Make requested changes
   - Request re-review
   - Update PR description if scope changes

### For Reviewers

1. **Be Timely**
   - Review within 24-48 hours
   - Leave a comment if delayed

2. **Be Constructive**
   - Explain why, not just what
   - Suggest alternatives
   - Praise good code

3. **Be Thorough**
   - Check all files
   - Test locally if possible
   - Consider edge cases

4. **Approve or Request Changes**
   - Clearly indicate status
   - Summarize main concerns
   - Re-review after changes

---

## Example Review

### PR: Add Fuzzy Matching Feature

**Files Changed**:
- `include/fuzzy.h` (new)
- `src/fuzzy.c` (new)
- `src/autocomplete.c` (modified)
- `plugin.zsh` (modified)
- `README.md` (modified)
- `tests/test_fuzzy.sh` (new)

**Review Comments**:

#### fuzzy.c
```c
// Line 45
int levenshtein_distance(const char* s1, const char* s2) {
    int len1 = strlen(s1);
    int len2 = strlen(s2);
    
    // Create DP table
    int** dp = malloc((len1 + 1) * sizeof(int*));
```

💬 **Comment**: "Please add NULL check after malloc. Also consider a stack-allocated array for small strings to avoid allocation overhead."

[DONE] **Suggestion**:
```c
// Use stack allocation for small strings
if (len1 < 100 && len2 < 100) {
    int dp[101][101];  // Stack allocation
    // ... use dp directly
} else {
    int** dp = malloc((len1 + 1) * sizeof(int*));
    if (!dp) {
        return -1;  // Allocation failed
    }
    // ... heap allocation path
}
```

#### autocomplete.c
```c
// Line 234
if (strcmp(operation, "fuzzy") == 0) {
    result = fuzzy_get_best_match(command_trie, current_buffer, 3);
```

💬 **Comment**: "The max distance is hard-coded to 3. Consider making this configurable via environment variable or argument."

[DONE] **Approved with minor changes**: The fuzzy matching implementation looks solid. Please address the comments above, then this is ready to merge.

---

## Conclusion

Effective code review:
- Catches bugs before production
- Shares knowledge across team
- Maintains code quality
- Improves design through discussion

Be respectful, constructive, and thorough. Code review is collaboration, not criticism.
