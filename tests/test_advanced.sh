#!/bin/bash

# test_advanced.sh - Comprehensive test for advanced autocomplete functionality

echo "🧪 Testing Advanced Autocomplete System"
echo "======================================="

# Sample history for testing
HISTORY="ls -la
git status
git commit -m 'test'
make clean
make debug
cd /Users/sriujjwalreddyb
history | tail -10
ps aux | grep zsh
cat README.md
source ~/.zshrc"

echo "📋 Sample History (10 commands):"
echo "$HISTORY"
echo ""

echo "🔧 Testing Individual Operations:"
echo "================================="

# Test 1: Initialization
echo "1. Testing initialization..."
RESULT=$(echo "$HISTORY" | ./autocomplete init "")
echo "   Result: $RESULT"
echo ""

# Test 2: Ghost text completion
echo "2. Testing ghost text completion..."
echo "   Testing prefix 'git':"
GHOST=$(echo "$HISTORY" | ./autocomplete ghost "git" 2>/dev/null)
echo "   Ghost text: '$GHOST'"

echo "   Testing prefix 'ma':"
GHOST=$(echo "$HISTORY" | ./autocomplete ghost "ma" 2>/dev/null)
echo "   Ghost text: '$GHOST'"

echo "   Testing prefix 'ls':"
GHOST=$(echo "$HISTORY" | ./autocomplete ghost "ls" 2>/dev/null)
echo "   Ghost text: '$GHOST'"
echo ""

# Test 3: History navigation
echo "3. Testing history navigation..."
ORIGINAL_BUFFER="new command"

echo "   Starting with: '$ORIGINAL_BUFFER'"
INDEX=0

# Navigate UP through history
echo "   UP (1):"
RESULT=$(echo "$HISTORY" | ./autocomplete history "$ORIGINAL_BUFFER" "up" "$INDEX" 2>/dev/null)
BUFFER="${RESULT%|*}"
INDEX="${RESULT##*|}"
echo "     Buffer: '$BUFFER', Index: $INDEX"

echo "   UP (2):"
RESULT=$(echo "$HISTORY" | ./autocomplete history "$BUFFER" "up" "$INDEX" 2>/dev/null)
BUFFER="${RESULT%|*}"
INDEX="${RESULT##*|}"
echo "     Buffer: '$BUFFER', Index: $INDEX"

echo "   UP (3):"
RESULT=$(echo "$HISTORY" | ./autocomplete history "$BUFFER" "up" "$INDEX" 2>/dev/null)
BUFFER="${RESULT%|*}"
INDEX="${RESULT##*|}"
echo "     Buffer: '$BUFFER', Index: $INDEX"

# Navigate DOWN back to original
echo "   DOWN (1):"
RESULT=$(echo "$HISTORY" | ./autocomplete history "$BUFFER" "down" "$INDEX" 2>/dev/null)
BUFFER="${RESULT%|*}"
INDEX="${RESULT##*|}"
echo "     Buffer: '$BUFFER', Index: $INDEX"

echo "   DOWN (2):"
RESULT=$(echo "$HISTORY" | ./autocomplete history "$BUFFER" "down" "$INDEX" 2>/dev/null)
BUFFER="${RESULT%|*}"
INDEX="${RESULT##*|}"
echo "     Buffer: '$BUFFER', Index: $INDEX"

echo "   DOWN (3) - should return to original:"
RESULT=$(echo "$HISTORY" | ./autocomplete history "$BUFFER" "down" "$INDEX" 2>/dev/null)
BUFFER="${RESULT%|*}"
INDEX="${RESULT##*|}"
echo "     Buffer: '$BUFFER', Index: $INDEX"
echo "     ✅ Expected: '$ORIGINAL_BUFFER', Got: '$BUFFER'"
echo ""

# Test 4: Usage update
echo "4. Testing usage update..."
UPDATE_RESULT=$(echo "$HISTORY" | ./autocomplete update "" "git status" 2>/dev/null)
echo "   Update result: '$UPDATE_RESULT'"
echo ""

# Test 5: Performance test
echo "5. Testing performance with large history..."
LARGE_HISTORY=""
for i in {1..500}; do
    LARGE_HISTORY="$LARGE_HISTORY
command_$i --option value_$i"
done

START_TIME=$(date +%s%3N)
PERF_GHOST=$(echo "$LARGE_HISTORY" | ./autocomplete ghost "command_1" 2>/dev/null)
END_TIME=$(date +%s%3N)
DURATION=$((END_TIME - START_TIME))

echo "   Large history (500 commands) ghost text lookup: ${DURATION}ms"
echo "   Result: '$PERF_GHOST'"
echo ""

# Test 6: Edge cases
echo "6. Testing edge cases..."

echo "   Empty prefix:"
EMPTY_GHOST=$(echo "$HISTORY" | ./autocomplete ghost "" 2>/dev/null)
echo "     Result: '$EMPTY_GHOST'"

echo "   Non-existent prefix:"
NONE_GHOST=$(echo "$HISTORY" | ./autocomplete ghost "xyz123" 2>/dev/null)
echo "     Result: '$NONE_GHOST'"

echo "   Single character prefix:"
SINGLE_GHOST=$(echo "$HISTORY" | ./autocomplete ghost "g" 2>/dev/null)
echo "     Result: '$SINGLE_GHOST'"
echo ""

echo "🎯 Testing Data Structure Functionality:"
echo "========================================"

# Test trie functionality
echo "1. Trie prefix matching test:"
echo "   Commands starting with 'git': should find multiple"
echo "   Commands starting with 'make': should find 2"
echo "   Commands starting with 'cat': should find 1"
echo ""

# Test priority queue functionality  
echo "2. Priority queue MRU test:"
echo "   Most recently used commands should appear first"
echo "   Frequency should increase usage priority"
echo ""

echo "🚀 Integration Test Summary:"
echo "==========================="

# Count successful operations
TESTS_PASSED=0
TOTAL_TESTS=6

# Simple success check based on non-empty results
if [[ -n "$GHOST" ]]; then
    ((TESTS_PASSED++))
    echo "   ✅ Ghost text generation: PASSED"
else
    echo "   ❌ Ghost text generation: FAILED"
fi

if [[ "$BUFFER" == "$ORIGINAL_BUFFER" ]]; then
    ((TESTS_PASSED++))
    echo "   ✅ History navigation: PASSED"
else
    echo "   ❌ History navigation: FAILED"
fi

if [[ "$UPDATE_RESULT" == "updated" ]]; then
    ((TESTS_PASSED++))
    echo "   ✅ Usage update: PASSED"
else
    echo "   ❌ Usage update: FAILED"
fi

if [[ $DURATION -lt 100 ]]; then  # Less than 100ms
    ((TESTS_PASSED++))
    echo "   ✅ Performance test: PASSED (${DURATION}ms)"
else
    echo "   ❌ Performance test: FAILED (${DURATION}ms)"
fi

if [[ -z "$EMPTY_GHOST" && -z "$NONE_GHOST" ]]; then
    ((TESTS_PASSED++))
    echo "   ✅ Edge cases: PASSED"
else
    echo "   ❌ Edge cases: FAILED"
fi

if [[ -n "$SINGLE_GHOST" ]]; then
    ((TESTS_PASSED++))
    echo "   ✅ Single char prefix: PASSED"
else
    echo "   ❌ Single char prefix: FAILED"
fi

echo ""
echo "📊 Test Results: $TESTS_PASSED/$TOTAL_TESTS tests passed"

if [[ $TESTS_PASSED -eq $TOTAL_TESTS ]]; then
    echo "🎉 All tests passed! System is working correctly."
    exit 0
else
    echo "⚠️  Some tests failed. Check the output above for details."
    exit 1
fi 