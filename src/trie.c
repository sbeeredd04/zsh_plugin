#include "trie.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

// Create a new trie node
TrieNode* trie_node_create(void) {
    TrieNode* node = malloc(sizeof(TrieNode));
    if (!node) return NULL;
    
    node->is_end_of_word = false;
    node->full_command = NULL;
    node->frequency = 0;
    node->last_used = 0;
    
    for (int i = 0; i < ALPHABET_SIZE; i++) {
        node->children[i] = NULL;
    }
    
    return node;
}

// Destroy a trie node and all its children
void trie_node_destroy(TrieNode* node) {
    if (!node) return;
    
    for (int i = 0; i < ALPHABET_SIZE; i++) {
        if (node->children[i]) {
            trie_node_destroy(node->children[i]);
        }
    }
    
    if (node->full_command) {
        free(node->full_command);
    }
    free(node);
}

// Create a new trie
Trie* trie_create(void) {
    Trie* trie = malloc(sizeof(Trie));
    if (!trie) return NULL;
    
    trie->root = trie_node_create();
    if (!trie->root) {
        free(trie);
        return NULL;
    }
    
    trie->total_commands = 0;
    return trie;
}

// Destroy the trie
void trie_destroy(Trie* trie) {
    if (!trie) return;
    
    trie_node_destroy(trie->root);
    free(trie);
}

// Insert a command into the trie
void trie_insert(Trie* trie, const char* command) {
    if (!trie || !command || strlen(command) == 0) return;
    
    TrieNode* current = trie->root;
    int len = strlen(command);
    
    // Traverse/create path for each character
    for (int i = 0; i < len; i++) {
        unsigned char index = (unsigned char)command[i];
        if (index >= ALPHABET_SIZE) continue;  // Skip invalid characters
        
        if (current->children[index] == NULL) {
            current->children[index] = trie_node_create();
            if (!current->children[index]) return;  // Memory allocation failed
        }
        current = current->children[index];
    }
    
    // Mark end of word and store the full command
    if (!current->is_end_of_word) {
        current->is_end_of_word = true;
        current->full_command = strdup(command);
        trie->total_commands++;
    }
    
    // Update frequency and last used time
    current->frequency++;
    current->last_used = time(NULL);
    
    // Only show debug output in debug mode
#ifdef DEBUG
    printf("DEBUG: Inserted '%s' (freq: %d, total commands: %d)\n", 
           command, current->frequency, trie->total_commands);
#endif
}

// Search for a prefix in the trie
bool trie_search(Trie* trie, const char* prefix) {
    if (!trie || !prefix) return false;
    
    TrieNode* current = trie->root;
    int len = strlen(prefix);
    
    for (int i = 0; i < len; i++) {
        unsigned char index = (unsigned char)prefix[i];
        if (index >= ALPHABET_SIZE || current->children[index] == NULL) {
            return false;
        }
        current = current->children[index];
    }
    
    return true;  // Prefix exists
}

// Get the best completion for a prefix (highest frequency + most recent)
char* trie_get_best_completion(Trie* trie, const char* prefix) {
    if (!trie || !prefix) return NULL;
    
    TrieNode* current = trie->root;
    int len = strlen(prefix);
    
    // Navigate to the prefix node
    for (int i = 0; i < len; i++) {
        unsigned char index = (unsigned char)prefix[i];
        if (index >= ALPHABET_SIZE || current->children[index] == NULL) {
#ifdef DEBUG
            printf("DEBUG: Prefix '%s' not found in trie\n", prefix);
#endif
            return NULL;
        }
        current = current->children[index];
    }
    
    // Find the best completion from this node
    TrieNode* best_node = NULL;
    int best_score = -1;
    
    // Simple DFS to find best completion
    // We'll use a stack-based approach to avoid recursion limits
    TrieNode* stack[1000];
    int stack_top = 0;
    
    stack[stack_top++] = current;
    
    while (stack_top > 0) {
        TrieNode* node = stack[--stack_top];
        
        if (node->is_end_of_word) {
            // Calculate score: frequency * 100 + recency bonus
            int recency_bonus = (time(NULL) - node->last_used < 3600) ? 50 : 0;  // 1 hour recency
            int score = node->frequency * 100 + recency_bonus;
            
            if (score > best_score) {
                best_score = score;
                best_node = node;
            }
        }
        
        // Add children to stack
        for (int i = 0; i < ALPHABET_SIZE && stack_top < 999; i++) {
            if (node->children[i]) {
                stack[stack_top++] = node->children[i];
            }
        }
    }
    
    if (best_node && best_node->full_command) {
#ifdef DEBUG
        printf("DEBUG: Best completion for '%s': '%s' (score: %d)\n", 
               prefix, best_node->full_command, best_score);
#endif
        return strdup(best_node->full_command);
    }
    
#ifdef DEBUG
    printf("DEBUG: No completion found for prefix '%s'\n", prefix);
#endif
    return NULL;
}

// Update frequency of a command (when user executes it)
void trie_update_frequency(Trie* trie, const char* command) {
    if (!trie || !command) return;
    
    TrieNode* current = trie->root;
    int len = strlen(command);
    
    // Navigate to the command node
    for (int i = 0; i < len; i++) {
        unsigned char index = (unsigned char)command[i];
        if (index >= ALPHABET_SIZE || current->children[index] == NULL) {
            return;  // Command not found
        }
        current = current->children[index];
    }
    
    if (current->is_end_of_word) {
        current->frequency++;
        current->last_used = time(NULL);
#ifdef DEBUG
        printf("DEBUG: Updated frequency for '%s' to %d\n", command, current->frequency);
#endif
    }
}

// Print debug information about the trie
void trie_print_debug(Trie* trie, const char* prefix) {
    if (!trie) return;
    
#ifdef DEBUG
    printf("DEBUG: Trie stats - Total commands: %d\n", trie->total_commands);
    
    if (prefix && strlen(prefix) > 0) {
        char* best = trie_get_best_completion(trie, prefix);
        if (best) {
            printf("DEBUG: Best completion for '%s': '%s'\n", prefix, best);
            free(best);
        } else {
            printf("DEBUG: No completion found for prefix '%s'\n", prefix);
        }
    }
#endif
} 