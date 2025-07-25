# Makefile - Zsh Autocomplete Plugin Build System

CC = gcc
CFLAGS = -O2 -Wall -Iinclude
DEBUG_CFLAGS = -g -Wall -DDEBUG -Iinclude

# Source directories
SRC_DIR     = src
INCLUDE_DIR = include

# Only trie + autocomplete; priority_queue removed
SOURCES = $(SRC_DIR)/autocomplete.c $(SRC_DIR)/trie.c
OBJECTS = autocomplete.o trie.o

# Default target
all: autocomplete

# Main binary
autocomplete: $(OBJECTS)
	$(CC) $(CFLAGS) -o autocomplete $(OBJECTS)

# Debug version
debug:
	$(CC) $(DEBUG_CFLAGS) -o autocomplete $(SOURCES)

# Compile object files
autocomplete.o: $(SRC_DIR)/autocomplete.c $(INCLUDE_DIR)/trie.h
	$(CC) $(CFLAGS) -c $< -o $@

trie.o: $(SRC_DIR)/trie.c $(INCLUDE_DIR)/trie.h
	$(CC) $(CFLAGS) -c $< -o $@

# Install target
install: autocomplete
	@echo "Installing autocomplete plugin..."
	@chmod +x autocomplete

# Test target
test: autocomplete
	@echo "Testing autocomplete binary..."
	@echo -e "git status\ngit commit\nmake clean" | ./autocomplete ghost "git" && echo " ✅ Ghost text test passed"
	@echo -e "ls -la\nps aux"           | ./autocomplete history "test" "up" "0" && echo " ✅ History navigation test passed"

# Clean up
clean:
	rm -f autocomplete *.o
	rm -rf data

# Clean and rebuild
rebuild: clean all

.PHONY: all debug install test clean rebuild
