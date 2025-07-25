# Makefile
CC = gcc
CFLAGS = -O2

all: hello

hello: hello.c
	$(CC) $(CFLAGS) -o hello hello.c

clean:
	rm -f hello 