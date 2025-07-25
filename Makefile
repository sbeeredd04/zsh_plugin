# Makefile
CC = gcc
CFLAGS = -O2

all: autocomplete

autocomplete: autocomplete.c
	$(CC) $(CFLAGS) -o autocomplete autocomplete.c

clean:
	rm -f autocomplete 