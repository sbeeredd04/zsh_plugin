#include "priority_queue.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

// Create a new command entry
CommandEntry* pq_create_entry(const char* command, int frequency, long timestamp) {
    CommandEntry* entry = malloc(sizeof(CommandEntry));
    if (!entry) return NULL;
    
    entry->command = strdup(command);
    entry->frequency = frequency;
    entry->timestamp = timestamp;
    entry->priority_score = pq_calculate_priority(frequency, timestamp);
    
    return entry;
}

// Destroy a command entry
void pq_destroy_entry(CommandEntry* entry) {
    if (!entry) return;
    
    if (entry->command) {
        free(entry->command);
    }
    free(entry);
}

// Calculate priority score (higher = more important)
int pq_calculate_priority(int frequency, long timestamp) {
    long current_time = time(NULL);
    long age_seconds = current_time - timestamp;
    
    // Frequency weight: 100 points per use
    int frequency_score = frequency * 100;
    
    // Recency weight: more recent = higher score
    int recency_score = 0;
    if (age_seconds < 300) {          // Last 5 minutes: 200 points
        recency_score = 200;
    } else if (age_seconds < 1800) {  // Last 30 minutes: 100 points
        recency_score = 100;
    } else if (age_seconds < 3600) {  // Last hour: 50 points
        recency_score = 50;
    } else if (age_seconds < 86400) { // Last day: 25 points
        recency_score = 25;
    }
    
    return frequency_score + recency_score;
}

// Create a new priority queue
PriorityQueue* pq_create(void) {
    PriorityQueue* pq = malloc(sizeof(PriorityQueue));
    if (!pq) return NULL;
    
    pq->size = 0;
    pq->capacity = MAX_MRU_SIZE;
    
    for (int i = 0; i < MAX_MRU_SIZE; i++) {
        pq->entries[i] = NULL;
    }
    
    return pq;
}

// Destroy the priority queue
void pq_destroy(PriorityQueue* pq) {
    if (!pq) return;
    
    for (int i = 0; i < pq->size; i++) {
        pq_destroy_entry(pq->entries[i]);
    }
    
    free(pq);
}

// Swap two entries
void pq_swap(CommandEntry** a, CommandEntry** b) {
    CommandEntry* temp = *a;
    *a = *b;
    *b = temp;
}

// Heapify up (for insertion)
void pq_heapify_up(PriorityQueue* pq, int index) {
    if (index <= 0) return;
    
    int parent = (index - 1) / 2;
    
    if (pq->entries[index]->priority_score > pq->entries[parent]->priority_score) {
        pq_swap(&pq->entries[index], &pq->entries[parent]);
        pq_heapify_up(pq, parent);
    }
}

// Heapify down (for extraction)
void pq_heapify_down(PriorityQueue* pq, int index) {
    int largest = index;
    int left = 2 * index + 1;
    int right = 2 * index + 2;
    
    if (left < pq->size && 
        pq->entries[left]->priority_score > pq->entries[largest]->priority_score) {
        largest = left;
    }
    
    if (right < pq->size && 
        pq->entries[right]->priority_score > pq->entries[largest]->priority_score) {
        largest = right;
    }
    
    if (largest != index) {
        pq_swap(&pq->entries[index], &pq->entries[largest]);
        pq_heapify_down(pq, largest);
    }
}

// Insert a command into the priority queue
void pq_insert(PriorityQueue* pq, const char* command, int frequency, long timestamp) {
    if (!pq || !command) return;
    
    // Check if command already exists
    for (int i = 0; i < pq->size; i++) {
        if (strcmp(pq->entries[i]->command, command) == 0) {
            // Update existing entry
            pq->entries[i]->frequency = frequency;
            pq->entries[i]->timestamp = timestamp;
            pq->entries[i]->priority_score = pq_calculate_priority(frequency, timestamp);
            
            // Re-heapify
            pq_heapify_up(pq, i);
            pq_heapify_down(pq, i);
            
            printf("DEBUG: Updated MRU entry for '%s' (priority: %d)\n", 
                   command, pq->entries[i]->priority_score);
            return;
        }
    }
    
    // If queue is full, remove the least priority item
    if (pq->size >= pq->capacity) {
        // Find minimum priority entry
        int min_index = 0;
        for (int i = 1; i < pq->size; i++) {
            if (pq->entries[i]->priority_score < pq->entries[min_index]->priority_score) {
                min_index = i;
            }
        }
        
        printf("DEBUG: Removing MRU entry '%s' to make space\n", 
               pq->entries[min_index]->command);
        
        pq_destroy_entry(pq->entries[min_index]);
        
        // Move last entry to removed position
        pq->entries[min_index] = pq->entries[pq->size - 1];
        pq->entries[pq->size - 1] = NULL;
        pq->size--;
        
        // Re-heapify from the moved position
        pq_heapify_up(pq, min_index);
        pq_heapify_down(pq, min_index);
    }
    
    // Insert new entry
    CommandEntry* entry = pq_create_entry(command, frequency, timestamp);
    if (!entry) return;
    
    pq->entries[pq->size] = entry;
    pq_heapify_up(pq, pq->size);
    pq->size++;
    
}

// Peek at the highest priority command
CommandEntry* pq_peek(PriorityQueue* pq) {
    if (!pq || pq->size == 0) return NULL;
    return pq->entries[0];
}

// Extract the highest priority command
CommandEntry* pq_extract_max(PriorityQueue* pq) {
    if (!pq || pq->size == 0) return NULL;
    
    CommandEntry* max_entry = pq->entries[0];
    
    // Move last entry to root
    pq->entries[0] = pq->entries[pq->size - 1];
    pq->entries[pq->size - 1] = NULL;
    pq->size--;
    
    // Re-heapify
    if (pq->size > 0) {
        pq_heapify_down(pq, 0);
    }
    
    return max_entry;
}

// Update a command's priority (when executed)
void pq_update_command(PriorityQueue* pq, const char* command) {
    if (!pq || !command) return;
    
    for (int i = 0; i < pq->size; i++) {
        if (strcmp(pq->entries[i]->command, command) == 0) {
            pq->entries[i]->frequency++;
            pq->entries[i]->timestamp = time(NULL);
            pq->entries[i]->priority_score = pq_calculate_priority(
                pq->entries[i]->frequency, pq->entries[i]->timestamp);
            
            // Re-heapify
            pq_heapify_up(pq, i);
            pq_heapify_down(pq, i);
            
            printf("DEBUG: Updated MRU command '%s' (new priority: %d)\n", 
                   command, pq->entries[i]->priority_score);
            return;
        }
    }
    
    // Command not found, insert it
    pq_insert(pq, command, 1, time(NULL));
}

// Check if queue contains a command
bool pq_contains(PriorityQueue* pq, const char* command) {
    if (!pq || !command) return false;
    
    for (int i = 0; i < pq->size; i++) {
        if (strcmp(pq->entries[i]->command, command) == 0) {
            return true;
        }
    }
    return false;
}

// Print debug information
void pq_print_debug(PriorityQueue* pq) {
    if (!pq) return;
    
    printf("DEBUG: Priority Queue - Size: %d/%d\n", pq->size, pq->capacity);
    
    for (int i = 0; i < pq->size && i < 5; i++) {  // Show top 5
        printf("DEBUG:   [%d] '%s' (freq: %d, priority: %d)\n", 
               i, pq->entries[i]->command, 
               pq->entries[i]->frequency, pq->entries[i]->priority_score);
    }
} 