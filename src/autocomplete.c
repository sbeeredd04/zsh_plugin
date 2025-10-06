/**
 * @file autocomplete.c
 * @brief Main autocomplete engine with persistent trie-based command storage
 * 
 * This is the core C program that powers the zsh autocomplete plugin. It provides
 * fast prefix matching, history filtering, and persistent command caching using
 * a trie data structure.
 * 
 * Architecture:
 * - Data Layer: Trie structure for O(k) prefix matching
 * - Storage Layer: Persistent cache in ~/.cache/zsh-autocomplete/
 * - Processing Layer: Command filtering and completion logic
 * - Interface Layer: Command-line argument parsing
 * 
 * Operations:
 * - init    : Load history from stdin and initialize cache
 * - ghost   : Get best completion for a prefix
 * - history : Navigate filtered command history
 * - update  : Update command frequency on execution
 * 
 * Performance:
 * - Ghost text: <5ms typical response time
 * - History filter: <10ms for 1000+ commands
 * - Memory usage: ~1MB for 1000 commands (thanks to trie prefix sharing)
 * 
 * @author sbeeredd04
 * @date 2025
 */

// autocomplete.c - Improved autocomplete with persistent trie storage
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <sys/stat.h>
#include <stdbool.h>
#include "../include/trie.h"
#include <sys/types.h>
#include <limits.h>

// Global data structures
static Trie* command_trie = NULL;
static char** history_array = NULL;
static int history_count = 0;
static char* current_prefix = NULL;
static char** filtered_history = NULL;
static int filtered_count = 0;
static int current_position = 0;
static bool is_initialized = false;

// Persistent storage paths
// #define DATA_DIR "data"
// #define TRIE_DATA_FILE "data/trie_data.txt"

// Cache paths
static char CACHE_DIR[PATH_MAX];
static char TRIE_DATA_FILE[PATH_MAX];

static void init_storage_paths(void) {
    const char *xdg = getenv("XDG_CACHE_HOME");
    if (!xdg || *xdg=='\0') {
        const char *home = getenv("HOME");
        snprintf(CACHE_DIR, sizeof(CACHE_DIR), "%s/.cache/zsh-autocomplete", home);
    } else {
        snprintf(CACHE_DIR, sizeof(CACHE_DIR), "%s/zsh-autocomplete", xdg);
    }
    snprintf(TRIE_DATA_FILE, sizeof(TRIE_DATA_FILE), "%s/trie_data.txt", CACHE_DIR);
}

static void ensure_data_directory(void) {
    struct stat st = {0};
    if (stat(CACHE_DIR, &st)==-1) {
        mkdir(CACHE_DIR, 0700);
    }
}

// Helper: find the trie node for a full command
static TrieNode* trie_find_node(Trie *t, const char *cmd) {
    TrieNode *cur = t->root;
    for (size_t i=0; i<strlen(cmd); i++) {
        unsigned char idx = (unsigned char)cmd[i];
        if (idx>=ALPHABET_SIZE || !cur->children[idx]) return NULL;
        cur = cur->children[idx];
    }
    return cur->is_end_of_word ? cur : NULL;
}

// Save trie + metadata to disk as "cmd|freq|last_used" lines
void save_trie_to_file(void) {
    if (!command_trie) return;
    init_storage_paths();
    ensure_data_directory();
    FILE *f = fopen(TRIE_DATA_FILE, "w");
    if (!f) return;

    for (int i=0; i<history_count; i++) {
        const char *cmd = history_array[i];
        TrieNode *node = trie_find_node(command_trie, cmd);
        int freq = node ? node->frequency : 1;
        long ts   = node ? node->last_used : time(NULL);
        fprintf(f, "%s|%d|%ld\n", cmd, freq, ts);
    }
    fclose(f);
}

// Load saved trie entries with their freq & timestamp; rebuild history_array
void load_trie_from_file(void) {
    init_storage_paths();
    FILE *f = fopen(TRIE_DATA_FILE, "r");
    if (!f) return;

    // clear existing
    if (history_array) {
        for (int i=0; i<history_count; i++) free(history_array[i]);
        free(history_array);
    }
    history_array = NULL;
    history_count = 0;

    size_t cap = 128;
    history_array = malloc(cap * sizeof(char*));
    char line[4096];
    while (fgets(line, sizeof(line), f)) {
        char *nl = strchr(line,'\n'); if(nl)*nl='\0';
        if (!*line) continue;
        char *cmd      = strtok(line,"|");
        char *freq_str = strtok(NULL,"|");
        char *ts_str   = strtok(NULL,"|");
        if (!cmd) continue;

        trie_insert(command_trie, cmd);
        TrieNode *node = trie_find_node(command_trie, cmd);
        if (node && freq_str && ts_str) {
            node->frequency = atoi(freq_str);
            node->last_used = atol(ts_str);
        }

        if (history_count >= (int)cap) {
            cap *= 2;
            history_array = realloc(history_array, cap * sizeof(char*));
        }
        history_array[history_count++] = strdup(cmd);
    }
    fclose(f);
}

// Function prototypes
static void initialize_autocomplete_from_stdin(void);
static void initialize_autocomplete_from_cache(void);
void cleanup_autocomplete(void);
int load_history_from_stdin(void);
void save_trie_to_file(void);
void load_trie_from_file(void);
char* get_ghost_text(const char* prefix);
static char* navigate_filtered_history(const char* prefix, const char* direction, int start_index, int* new_index);
void update_command_usage(const char* command);
void filter_history_by_prefix(const char* prefix);

// Create data directory if it doesn't exist
// void ensure_data_directory(void) {
//     struct stat st = {0};
//     if (stat(DATA_DIR, &st) == -1) {
//         mkdir(DATA_DIR, 0700);
//     }
// }

// Save trie data to persistent file
// void save_trie_to_file(void) {
//     if (!command_trie) return;
    
//     ensure_data_directory();
//     FILE* file = fopen(TRIE_DATA_FILE, "w");
//     if (!file) return;
    
//     // Save history array for easy reconstruction
//     fprintf(file, "%d\n", history_count);
//     for (int i = 0; i < history_count; i++) {
//         if (history_array[i]) {
//             fprintf(file, "%s\n", history_array[i]);
//         }
//     }
    
//     fclose(file);
// }

#pragma region INITIALIZATION_FUNCS

/**
 * Initialize autocomplete system from stdin with cache fallback.
 * 
 * This function should be called ONCE per shell session via the 'init' operation.
 * It reads command history from stdin and compares with the on-disk cache,
 * keeping whichever dataset is larger. This ensures we don't lose commands
 * when the shell history is cleared.
 * 
 * Flow:
 * 1. Create empty trie
 * 2. Check cache file size
 * 3. Load commands from stdin
 * 4. If stdin > cache, save new data to cache
 * 5. Otherwise, reload from cache
 * 
 * @note This function blocks on stdin, so it should only be called
 *       when history data is being piped (not from interactive terminal)
 * @note Sets is_initialized = true to prevent double initialization
 * 
 * @see load_history_from_stdin
 * @see save_trie_to_file
 * @see load_trie_from_file
 */
static void initialize_autocomplete_from_stdin(void) {
    if (is_initialized) return;
    
    command_trie = trie_create();
    if (!command_trie) return;
    
    init_storage_paths();
    ensure_data_directory();

    // Try to load from cache first
    int cache_count = 0;
    FILE* file = fopen(TRIE_DATA_FILE, "r");
    if (file) {
        char line[2048];
        if (fgets(line, sizeof(line), file)) {
            cache_count = atoi(line);
        }
        fclose(file);
    }
    
    // Load from stdin (always prefer larger set)
    int stdin_count = load_history_from_stdin();
    fprintf(stderr, "[DEBUG] initialize_autocomplete: stdin_count=%d, cache_count=%d\n", stdin_count, cache_count);
    if (stdin_count > cache_count) {
        // Save new, larger history to cache
        save_trie_to_file();
        fprintf(stderr, "[DEBUG] Saved new trie to cache (count=%d)\n", stdin_count);
    } else if (cache_count > 0) {
        // Reload from cache if it's larger
        load_trie_from_file();
        fprintf(stderr, "[DEBUG] Loaded trie from cache (count=%d)\n", cache_count);
    }
    fprintf(stderr, "[DEBUG] Trie total_commands after init: %d\n", command_trie->total_commands);
    is_initialized = true;
}

/**
 * Initialize autocomplete system from cache file only.
 * 
 * This variant is used for all operations EXCEPT 'init', because those operations
 * are called from interactive shell contexts where reading from stdin would block.
 * It loads previously cached command data from disk.
 * 
 * Flow:
 * 1. Create empty trie
 * 2. Load commands from cache file
 * 3. If cache doesn't exist, trie remains empty (graceful degradation)
 * 
 * @note Does NOT read from stdin - safe to call from interactive contexts
 * @note Sets is_initialized = true to prevent double initialization
 * @note If cache file is missing, creates empty trie (no error)
 * 
 * @see load_trie_from_file
 */
static void initialize_autocomplete_from_cache(void) {
    if (is_initialized) return;

    command_trie = trie_create();
    if (!command_trie) return;

    init_storage_paths();
    ensure_data_directory();

    load_trie_from_file();
    fprintf(stderr, "[DEBUG] initialize_autocomplete_from_cache: commands=%d\n", command_trie->total_commands);
    is_initialized = true;
}

#pragma endregion INITIALIZATION_FUNCS

// Load history from stdin and populate trie
int load_history_from_stdin(void) {
    char *line = NULL;
    size_t len = 0;
    ssize_t read;
    int count = 0;
    int capacity = 1000;
    
    history_array = malloc(capacity * sizeof(char*));
    if (!history_array) return 0;
    
    // Read history entries from stdin  
    while ((read = getline(&line, &len, stdin)) != -1) {
        // Remove newline character
        if (read > 0 && line[read-1] == '\n') {
            line[read-1] = '\0';
            read--;
        }
        
        if (read == 0) continue;
        
        // Resize if needed
        if (count >= capacity) {
            capacity *= 2;
            char **temp = realloc(history_array, capacity * sizeof(char*));
            if (!temp) break;
            history_array = temp;
        }
        
        // Store and insert into trie
        history_array[count] = strdup(line);
        trie_insert(command_trie, line);
        count++;
    }
    
    free(line);
    history_count = count; // Update global history count
    fprintf(stderr, "[DEBUG] Loaded %d lines from stdin into trie\n", count);
    return count;
}

// Load trie data from persistent file
// void load_trie_from_file(void) {
//     FILE* file = fopen(TRIE_DATA_FILE, "r");
//     if (!file) return;
    
//     char line[2048];
    
//     // Read count
//     if (fgets(line, sizeof(line), file)) {
//         history_count = atoi(line);
        
//         if (history_count > 0) {
//             history_array = malloc(history_count * sizeof(char*));
//             if (!history_array) {
//                 fclose(file);
//                 return;
//             }
            
//             // Read history entries and rebuild trie
//             int loaded = 0;
//             while (fgets(line, sizeof(line), file) && loaded < history_count) {
//                 // Remove newline
//                 size_t len = strlen(line);
//                 if (len > 0 && line[len-1] == '\n') {
//                     line[len-1] = '\0';
//                 }
                
//                 if (strlen(line) > 0) {
//                     history_array[loaded] = strdup(line);
//                     trie_insert(command_trie, line);
//                     loaded++;
//                 }
//             }
            
//             history_count = loaded;
// #ifdef DEBUG
//             printf("DEBUG: Loaded %d commands from cache\n", history_count);
// #endif
//         }
//     }
    
//     fclose(file);
// }

// Filter history array by prefix
void filter_history_by_prefix(const char* prefix) {
    if (filtered_history) {
        free(filtered_history);
        filtered_history = NULL;
    }
    
    filtered_count = 0;
    current_position = 0;
    
    if (!prefix || strlen(prefix) == 0) {
        // No prefix, use all history
        filtered_history = malloc(history_count * sizeof(char*));
        if (filtered_history) {
            for (int i = 0; i < history_count; i++) {
                filtered_history[filtered_count++] = history_array[i];
            }
        }
        fprintf(stderr, "[DEBUG] filter_history_by_prefix: prefix='' (all), count=%d\n", filtered_count);
        return;
    }
    
    // Filter by prefix
    int capacity = 100;
    filtered_history = malloc(capacity * sizeof(char*));
    if (!filtered_history) return;
    
    for (int i = 0; i < history_count; i++) {
        if (strncmp(history_array[i], prefix, strlen(prefix)) == 0) {
            if (filtered_count >= capacity) {
                capacity *= 2;
                char **temp = realloc(filtered_history, capacity * sizeof(char*));
                if (!temp) break;
                filtered_history = temp;
            }
            filtered_history[filtered_count++] = history_array[i];
        }
    }
    fprintf(stderr, "[DEBUG] filter_history_by_prefix: prefix='%s', count=%d\n", prefix, filtered_count);
}

// Get ghost text completion for a prefix
char* get_ghost_text(const char* prefix) {
    if (!prefix || strlen(prefix) == 0) return NULL;
    
    char* completion = trie_get_best_completion(command_trie, prefix);
    
    if (completion) {
#ifdef DEBUG
        printf("DEBUG: Ghost text for '%s': '%s'\n", prefix, completion);
#endif
        return completion;
    }
    
    return NULL;
}

// Navigate through filtered history based on prefix
char* navigate_filtered_history(const char* prefix, const char* direction, int start_index, int* new_index) {
    // Build filtered history every call (stateless between processes)
    const char* effective_prefix = (prefix && strlen(prefix) > 0) ? prefix : "";
    filter_history_by_prefix(effective_prefix);

    if (filtered_count == 0) {
        *new_index = 0;
        return strdup(prefix); // No matches, return original
    }

    int idx = start_index;
    if (strcmp(direction, "up") == 0) {
        idx++;
    } else if (strcmp(direction, "down") == 0) {
        idx--;
    }

    // Wrap behaviour: -1 represents the original (unmodified) buffer
    if (idx >= filtered_count) {
        idx = -1;
    } else if (idx < -1) {
        idx = filtered_count - 1;
    }

    *new_index = idx;

    if (idx == -1) {
        return strdup(prefix);
    } else {
        int actual_idx = filtered_count - 1 - idx; // Map to newest-to-oldest order
        if (actual_idx < 0 || actual_idx >= filtered_count) actual_idx = 0;
        return strdup(filtered_history[actual_idx]);
    }
}

// Update command usage when executed
void update_command_usage(const char* command) {
    if (!command || strlen(command) == 0) return;
    
#ifdef DEBUG
    printf("DEBUG: Updating usage for: '%s'\n", command);
#endif
    
    // Add to trie if not exists
    trie_insert(command_trie, command);
    
    // Add to history array if not exists
    bool exists = false;
    for (int i = 0; i < history_count; i++) {
        if (strcmp(history_array[i], command) == 0) {
            exists = true;
            break;
        }
    }
    
    if (!exists) {
        history_array = realloc(history_array, (history_count + 1) * sizeof(char*));
        if (history_array) {
            history_array[history_count] = strdup(command);
            history_count++;
        }
    }
    
    // Update frequency in trie
    trie_update_frequency(command_trie, command);
    
    // Save to cache
    save_trie_to_file();
    
#ifdef DEBUG
    printf("DEBUG: Updated and saved\n");
#endif
}

// Cleanup function
void cleanup_autocomplete(void) {
    if (command_trie) {
        trie_destroy(command_trie);
        command_trie = NULL;
    }
    
    if (history_array) {
        for (int i = 0; i < history_count; i++) {
            free(history_array[i]);
        }
        free(history_array);
        history_array = NULL;
    }
    
    if (filtered_history) {
        free(filtered_history);
        filtered_history = NULL;
    }
    
    if (current_prefix) {
        free(current_prefix);
        current_prefix = NULL;
    }
    
    history_count = 0;
    filtered_count = 0;
    current_position = 0;
    is_initialized = false;
}

int main(int argc, char *argv[]) {
    fprintf(stderr, "[DEBUG] autocomplete main() invoked with argc=%d\n", argc);
    for (int i = 0; i < argc; i++) {
        fprintf(stderr, "[DEBUG] argv[%d]='%s'\n", i, argv[i]);
    }
    if (argc < 2) {
        printf("Usage: %s <operation> [args...]\n", argv[0]);
        return 1;
    }
    char* operation = argv[1];
    char* current_buffer = (argc > 2) ? argv[2] : "";
    char* param3 = (argc > 3) ? argv[3] : "";
    
    // Initialise system differently depending on operation so we don't block on stdin.
    if (strcmp(operation, "init") == 0) {
        initialize_autocomplete_from_stdin();
    } else {
        initialize_autocomplete_from_cache();
    }
    char* result = NULL;
    if (strcmp(operation, "ghost") == 0) {
        // Get ghost text completion
        result = get_ghost_text(current_buffer);
        if (result) {
            printf("%s", result);
        }
    } else if (strcmp(operation, "history") == 0) {
        // Navigate filtered history
        const char* direction = param3;
        int start_index = 0;
        if (argc > 4) {
            start_index = atoi(argv[4]);
        }
        int new_index;
        result = navigate_filtered_history(current_buffer, direction, start_index, &new_index);
        if (result) {
            printf("%s|%d", result, new_index);
        }
    } else if (strcmp(operation, "update") == 0) {
        // Update command usage
        update_command_usage(param3);
    } else if (strcmp(operation, "init") == 0) {
        // Just initialize (already done above)
    } else {
        cleanup_autocomplete();
        return 1;
    }
    if (result) {
        free(result);
    }
    return 0;
} 