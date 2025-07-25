#!/bin/bash

# test_debug.sh - Test script to simulate autocomplete navigation

echo "🧪 Testing Autocomplete Navigation with Debug Output"
echo "================================================="

# Sample history
HISTORY="ls -la
git status  
make clean
history"

echo "📋 Sample History:"
echo "$HISTORY"
echo ""

echo "🔄 Simulating Navigation Sequence:"
echo "1. User types: 'git commit'"
echo "2. Press UP arrow (should get first history item)"
echo "3. Press UP arrow again (should get second history item)"  
echo "4. Press DOWN arrow (should go back to first history item)"
echo "5. Press DOWN arrow again (should return to original 'git commit')"
echo ""

INDEX=0
BUFFER="git commit"

echo "Starting with buffer: '$BUFFER', index: $INDEX"
echo ""

# Test UP navigation
echo "▲ UP (1): "
RESULT=$(echo "$HISTORY" | ./autocomplete "$BUFFER" "up" "$INDEX" 2>/dev/null)
BUFFER="${RESULT%|*}"
INDEX="${RESULT##*|}"
echo "   Buffer: '$BUFFER', Index: $INDEX"

echo "▲ UP (2): "
RESULT=$(echo "$HISTORY" | ./autocomplete "$BUFFER" "up" "$INDEX" 2>/dev/null)
BUFFER="${RESULT%|*}" 
INDEX="${RESULT##*|}"
echo "   Buffer: '$BUFFER', Index: $INDEX"

echo "▲ UP (3): "
RESULT=$(echo "$HISTORY" | ./autocomplete "$BUFFER" "up" "$INDEX" 2>/dev/null)
BUFFER="${RESULT%|*}"
INDEX="${RESULT##*|}"
echo "   Buffer: '$BUFFER', Index: $INDEX"

# Test DOWN navigation
echo "▼ DOWN (1): "
RESULT=$(echo "$HISTORY" | ./autocomplete "$BUFFER" "down" "$INDEX" 2>/dev/null)
BUFFER="${RESULT%|*}"
INDEX="${RESULT##*|}"
echo "   Buffer: '$BUFFER', Index: $INDEX"

echo "▼ DOWN (2): "
RESULT=$(echo "$HISTORY" | ./autocomplete "$BUFFER" "down" "$INDEX" 2>/dev/null)
BUFFER="${RESULT%|*}"
INDEX="${RESULT##*|}"
echo "   Buffer: '$BUFFER', Index: $INDEX"

echo "▼ DOWN (3): "
RESULT=$(echo "$HISTORY" | ./autocomplete "$BUFFER" "down" "$INDEX" 2>/dev/null)
BUFFER="${RESULT%|*}"
INDEX="${RESULT##*|}"
echo "   Buffer: '$BUFFER', Index: $INDEX"

echo ""
echo "🎯 Expected: Final buffer should be 'git commit' (original user input)"
echo "✅ Test complete!" 