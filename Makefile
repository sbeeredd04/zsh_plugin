# Makefile
ZSH = $(shell which zsh)
ZSHMODDIR = $(shell $(ZSH) -c 'echo $$module_path[1]')
CFLAGS = -fPIC -Wall -I$(ZSH)/../include

all: zsh_plugin.so

zsh_plugin.so: zsh_plugin.c
	$(CC) $(CFLAGS) -shared -o $@ $<

install:
	cp zsh_plugin.so $(ZSHMODDIR)

clean:
	rm -f zsh_plugin.so 