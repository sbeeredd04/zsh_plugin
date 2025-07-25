# Makefile
CC = gcc
CFLAGS = -O2 -Wall
DEBUG_CFLAGS = -g -Wall -DDEBUG

all: autocomplete

autocomplete: autocomplete.c
	$(CC) $(CFLAGS) -o autocomplete autocomplete.c

debug: autocomplete.c
	$(CC) $(DEBUG_CFLAGS) -o autocomplete autocomplete.c

clean:
	rm -f autocomplete

.PHONY: all debug clean 