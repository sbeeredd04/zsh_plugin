/**
 * @file trie.h
 * @brief Trie data structure interface for fast command prefix matching
 * 
 * This header defines the trie (prefix tree) data structure used for storing
 * and retrieving shell commands with O(k) time complexity where k is the
 * command length.
 * 
 * Features:
 * - Prefix-based search and completion
 * - Frequency tracking for usage-based ranking
 * - Timestamp tracking for recency-based ranking
 * - Memory-efficient prefix sharing
 * 
 * @author sbeeredd04
 * @date 2025
 */

#ifndef TRIE_H
#define TRIE_H

#include <stdbool.h>

/** Maximum number of children per node (ASCII character set) */
#define ALPHABET_SIZE 128

/** Maximum supported command length in characters */
#define MAX_COMMAND_LENGTH 1024

/**
 * @struct TrieNode
 * @brief Single node in the trie structure
 * 
 * Each node represents one character in a command prefix path.
 * Nodes can have up to ALPHABET_SIZE children (one for each ASCII character).
 * End-of-word nodes store the complete command string and usage metadata.
 */
typedef struct TrieNode {
    /** Array of child node pointers, indexed by ASCII character value */
    struct TrieNode* children[ALPHABET_SIZE];
    
    /** True if this node represents the end of a complete command */
    bool is_end_of_word;
    
    /** Complete command string (only set for end-of-word nodes) */
    char* full_command;
    
    /** Number of times this command has been executed */
    int frequency;
    
    /** Unix timestamp of last command execution */
    long last_used;
} TrieNode;

/**
 * @struct Trie
 * @brief Container structure for the trie with metadata
 * 
 * Maintains the root node and statistics about stored commands.
 */
typedef struct {
    /** Root node of the trie (always non-NULL after creation) */
    TrieNode* root;
    
    /** Total number of unique commands stored in the trie */
    int total_commands;
} Trie;

/* ============================================================================
 * Public API - Trie Management
 * ============================================================================ */

/**
 * Create a new empty trie structure.
 * 
 * @return Pointer to new Trie, or NULL if allocation fails
 * @note Caller must call trie_destroy() when done
 */
/**
 * Create a new empty trie structure.
 * 
 * @return Pointer to new Trie, or NULL if allocation fails
 * @note Caller must call trie_destroy() when done
 */
Trie* trie_create(void);

/**
 * Destroy a trie and free all allocated memory.
 * 
 * Recursively frees all nodes and their associated command strings.
 * Safe to call with NULL pointer (no-op).
 * 
 * @param trie  Trie to destroy (can be NULL)
 */
void trie_destroy(Trie* trie);

/**
 * Insert a command into the trie.
 * 
 * If command already exists, increments frequency and updates timestamp.
 * Otherwise, creates new path and initializes metadata.
 * 
 * @param trie     Trie to insert into (must not be NULL)
 * @param command  Command string to insert (must not be NULL/empty)
 * 
 * @note Time: O(k) where k = command length
 * @note Space: O(k) worst case (all new nodes)
 */
void trie_insert(Trie* trie, const char* command);

/**
 * Check if a prefix exists in the trie.
 * 
 * @param trie    Trie to search (must not be NULL)
 * @param prefix  Prefix string to search for
 * @return true if prefix exists, false otherwise
 * 
 * @note Time: O(k) where k = prefix length
 */
bool trie_search(Trie* trie, const char* prefix);

/**
 * Get all completions for a prefix (not currently used).
 * 
 * @param trie    Trie to search
 * @param prefix  Prefix to complete
 * @param count   Output: number of completions found
 * @return Array of completion strings (caller must free)
 */
char** trie_get_completions(Trie* trie, const char* prefix, int* count);

/**
 * Get the best single completion for a prefix.
 * 
 * Uses scoring algorithm: score = frequency × 100 + recency_bonus
 * where recency_bonus = 50 if used within last hour, 0 otherwise.
 * 
 * @param trie    Trie to search (must not be NULL)
 * @param prefix  Prefix to complete (can be empty for all commands)
 * @return Best matching command (caller must free), or NULL if none found
 * 
 * @note Time: O(n) where n = nodes in prefix subtree
 * @note Returns newly allocated string - caller must free()
 */
char* trie_get_best_completion(Trie* trie, const char* prefix);

/**
 * Update frequency and timestamp for a command.
 * 
 * Call this when user executes a command to improve future rankings.
 * 
 * @param trie     Trie containing the command
 * @param command  Command that was executed
 * 
 * @note Command must already exist in trie (no-op if not found)
 */
void trie_update_frequency(Trie* trie, const char* command);

/**
 * Print debug information about the trie (DEBUG builds only).
 * 
 * @param trie    Trie to debug
 * @param prefix  Optional prefix to show best completion for
 */
void trie_print_debug(Trie* trie, const char* prefix);

/* ============================================================================
 * Internal Helper Functions
 * ============================================================================ */

/**
 * Create a new trie node (internal use only).
 * 
 * @return Pointer to new TrieNode, or NULL if allocation fails
 */
TrieNode* trie_node_create(void);

/**
 * Destroy a trie node and all descendants (internal use only).
 * 
 * @param node  Node to destroy (can be NULL)
 */
void trie_node_destroy(TrieNode* node);

/**
 * Collect all completions under a node (internal use only).
 * 
 * @param node        Root node to search under
 * @param prefix      Current prefix being built
 * @param results     Array to store results
 * @param count       Current count of results
 * @param max_results Maximum results to collect
 */
void trie_collect_completions(TrieNode* node, const char* prefix, char** results, int* count, int max_results);

#endif // TRIE_H 