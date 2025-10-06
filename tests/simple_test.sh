#!/bin/bash

# simple_test.sh - Basic functionality test for autocomplete plugin

echo "Testing Zsh Autocomplete Plugin"
echo "=================================="

# Test ghost text
echo "1. Testing ghost text completion..."
GHOST=$(echo -e "git status\ngit commit\nmake clean" | ./autocomplete ghost "git" 2>/dev/null)
if [[ -n "$GHOST" ]]; then
    echo "   [PASS] Ghost text: '$GHOST'"
else
    echo "   [FAIL] Ghost text failed"
fi

# Test history navigation
echo "2. Testing history navigation..."
RESULT=$(echo -e "ls -la\nps aux\nvim file.txt" | ./autocomplete history "v" "up" "0" 2>/dev/null)
if [[ -n "$RESULT" ]]; then
    echo "   [PASS] History result: '$RESULT'"
else
    echo "   [FAIL] History navigation failed"
fi

# Test usage update
echo "3. Testing usage update..."
UPDATE=$(echo -e "test command" | ./autocomplete update "" "test command" 2>/dev/null)
if [[ "$UPDATE" == "updated" ]]; then
    echo "   [PASS] Usage update successful"
else
    echo "   [FAIL] Usage update failed: '$UPDATE'"
fi

# Test persistent storage
echo "4. Testing persistent storage..."
if [[ -d "data" ]]; then
    echo "   [PASS] Data directory created"
    if [[ -f "data/trie_data.txt" ]]; then
        echo "   [PASS] Trie data file exists"
    else
        echo "   [INFO] Trie data file not found (may be created after first use)"
    fi
else
    echo "   [INFO] Data directory not found (will be created on first use)"
fi

echo ""
echo "Basic tests completed!" 