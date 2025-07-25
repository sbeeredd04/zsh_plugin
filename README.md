# zsh_plugin

A minimal Zsh C module that registers a ZLE widget.

## Build

```sh
make
```

## Install

```sh
make install
```

Or copy `zsh_plugin.so` to a directory in your `$module_path`.

## Usage

Add to your `.zshrc`:

```sh
zmodload ./zsh_plugin.so
zle -N zle-hello
bindkey '^x^h' zle-hello  # Ctrl-x Ctrl-h to trigger
```

Restart your shell and press `Ctrl-x Ctrl-h` to insert "Hello from C!" at the cursor.

## Resources

- [Zsh Modules Documentation](https://zsh.sourceforge.io/Doc/Release/Zsh-Modules.html)
- [Zsh Line Editor (ZLE)](https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html)
- [zsh/example module](https://zsh.sourceforge.io/Doc/Release/Zsh-Modules.html#The-zsh_002fexample-Module)

## How to Expand

- Implement your trie/history logic in C.
- Register more ZLE widgets for navigation, ghost text, etc.
- Use the ZLE API to read/modify the command line buffer.

**This setup will get you started with a working C-based Zsh plugin.**