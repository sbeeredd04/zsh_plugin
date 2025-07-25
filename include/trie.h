#ifndef TRIE_H
#define TRIE_H

#include <stdbool.h>

#define ALPHABET_SIZE 128  // ASCII characters
#define MAX_COMMAND_LENGTH 1024

// Trie node structure
typedef struct TrieNode {
    struct TrieNode* children[ALPHABET_SIZE];
    bool is_end_of_word;
    char* full_command;      // Store the complete command at end nodes
    int frequency;           // How often this command was used
    long last_used;          // Timestamp of last use
} TrieNode;

// Trie structure
typedef struct {
    TrieNode* root;
    int total_commands;
} Trie;

// Function declarations
Trie* trie_create(void);
void trie_destroy(Trie* trie);
void trie_insert(Trie* trie, const char* command);
bool trie_search(Trie* trie, const char* prefix);
char** trie_get_completions(Trie* trie, const char* prefix, int* count);
char* trie_get_best_completion(Trie* trie, const char* prefix);
void trie_update_frequency(Trie* trie, const char* command);
void trie_print_debug(Trie* trie, const char* prefix);

// Helper functions
TrieNode* trie_node_create(void);
void trie_node_destroy(TrieNode* node);
void trie_collect_completions(TrieNode* node, const char* prefix, char** results, int* count, int max_results);

#endif // TRIE_H 