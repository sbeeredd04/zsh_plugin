// autocomplete.c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Dynamic history storage
static char **history_entries = NULL;
static int total_history_entries = 0;
static char *original_buffer = NULL;  // Store what user was typing

void cleanup_memory() {
    // Free allocated memory
    if (history_entries) {
        for (int i = 0; i < total_history_entries; i++) {
            free(history_entries[i]);
        }
        free(history_entries);
    }
    if (original_buffer) {
        free(original_buffer);
    }
}

int load_history_from_stdin(const char *current_buffer) {
    char *line = NULL;
    size_t len = 0;
    ssize_t read;
    int count = 0;
    int capacity = 100;  // Start with 100, will grow as needed
    
    // Allocate initial array
    history_entries = malloc(capacity * sizeof(char*));
    if (!history_entries) {
        return 0;
    }
    
    // Store the current buffer as entry 0 (what user was typing)
    original_buffer = strdup(current_buffer ? current_buffer : "");
    history_entries[0] = strdup(original_buffer);
    count = 1;
    
    // Read history entries from stdin
    while ((read = getline(&line, &len, stdin)) != -1) {
        // Remove newline character
        if (read > 0 && line[read-1] == '\n') {
            line[read-1] = '\0';
            read--;
        }
        
        // Skip empty lines
        if (read == 0) {
            continue;
        }
        
        // Skip if it's the same as current buffer (avoid duplicates)
        if (current_buffer && strcmp(line, current_buffer) == 0) {
            continue;
        }
        
        // Resize array if needed
        if (count >= capacity) {
            capacity *= 2;
            char **temp = realloc(history_entries, capacity * sizeof(char*));
            if (!temp) {
                break;
            }
            history_entries = temp;
        }
        
        // Store the history entry
        history_entries[count] = strdup(line);
        if (!history_entries[count]) {
            break;
        }
        count++;
    }
    
    // Clean up getline buffer
    free(line);
    
    return count;
}

int main(int argc, char *argv[]) {
    // argv[1] = current buffer content
    // argv[2] = direction ("up" or "down")
    // argv[3] = current position index (optional)
    
    if (argc < 2) {
        printf("");  // No input, return empty
        return 0;
    }
    
    char *current_buffer = argv[1];
    char *direction = (argc > 2) ? argv[2] : "up";
    int current_index = (argc > 3) ? atoi(argv[3]) : 0;  // Get current position
    
    // Load history from stdin, including current buffer
    total_history_entries = load_history_from_stdin(current_buffer);
    
    if (total_history_entries == 0) {
        printf("");  // No history available
        cleanup_memory();
        return 0;
    }
    
    // Navigate through history
    if (strcmp(direction, "up") == 0) {
        // Navigate backwards in history (older commands)
        current_index = (current_index + 1) % total_history_entries;
    } else if (strcmp(direction, "down") == 0) {
        // Navigate forwards in history (newer commands)
        current_index = (current_index - 1 + total_history_entries) % total_history_entries;
    }
    
    // Return the history entry followed by the new index
    printf("%s|%d", history_entries[current_index], current_index);
    
    cleanup_memory();
    return 0;
} 