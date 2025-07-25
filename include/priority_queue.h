#ifndef PRIORITY_QUEUE_H
#define PRIORITY_QUEUE_H

#include <stdbool.h>

#define MAX_MRU_SIZE 100  // Maximum number of MRU commands to track

// Command entry for priority queue
typedef struct {
    char* command;
    long timestamp;
    int frequency;
    int priority_score;  // Combined score of frequency and recency
} CommandEntry;

// Priority queue structure
typedef struct {
    CommandEntry* entries[MAX_MRU_SIZE];
    int size;
    int capacity;
} PriorityQueue;

// Function declarations
PriorityQueue* pq_create(void);
void pq_destroy(PriorityQueue* pq);
void pq_insert(PriorityQueue* pq, const char* command, int frequency, long timestamp);
CommandEntry* pq_peek(PriorityQueue* pq);
CommandEntry* pq_extract_max(PriorityQueue* pq);
void pq_update_command(PriorityQueue* pq, const char* command);
bool pq_contains(PriorityQueue* pq, const char* command);
void pq_print_debug(PriorityQueue* pq);

// Helper functions
void pq_heapify_up(PriorityQueue* pq, int index);
void pq_heapify_down(PriorityQueue* pq, int index);
void pq_swap(CommandEntry** a, CommandEntry** b);
int pq_calculate_priority(int frequency, long timestamp);
CommandEntry* pq_create_entry(const char* command, int frequency, long timestamp);
void pq_destroy_entry(CommandEntry* entry);

#endif // PRIORITY_QUEUE_H 