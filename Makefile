# Makefile - Zsh Autocomplete Plugin Build System
CC = gcc
CFLAGS = -O2 -Wall -Iinclude
DEBUG_CFLAGS = -g -Wall -DDEBUG -Iinclude

# Source files
SRC_DIR = src
INCLUDE_DIR = include
SOURCES = $(SRC_DIR)/autocomplete.c $(SRC_DIR)/trie.c $(SRC_DIR)/priority_queue.c
OBJECTS = autocomplete.o trie.o priority_queue.o

# Default target
all: autocomplete

# Main binary
autocomplete: $(OBJECTS)
	$(CC) $(CFLAGS) -o autocomplete $(OBJECTS)

# Debug version
debug: 
	$(CC) $(DEBUG_CFLAGS) -o autocomplete $(SOURCES)

# Individual object files
autocomplete.o: $(SRC_DIR)/autocomplete.c $(INCLUDE_DIR)/trie.h
	$(CC) $(CFLAGS) -c $(SRC_DIR)/autocomplete.c

trie.o: $(SRC_DIR)/trie.c $(INCLUDE_DIR)/trie.h
	$(CC) $(CFLAGS) -c $(SRC_DIR)/trie.c

priority_queue.o: $(SRC_DIR)/priority_queue.c $(INCLUDE_DIR)/priority_queue.h
	$(CC) $(CFLAGS) -c $(SRC_DIR)/priority_queue.c

# Install target
install: autocomplete
	@echo "Installing autocomplete plugin..."
	@chmod +x autocomplete

# Test target
test: autocomplete
	@echo "Testing autocomplete binary..."
	@echo -e "git status\ngit commit\nmake clean" | ./autocomplete ghost "git" && echo " ✅ Ghost text test passed"
	@echo -e "ls -la\nps aux" | ./autocomplete history "test" "up" "0" && echo " ✅ History navigation test passed"

# Clean up
clean:
	rm -f autocomplete *.o
	rm -rf data

# Clean and rebuild
rebuild: clean all

.PHONY: all debug install test clean rebuild 