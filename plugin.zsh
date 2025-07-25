# plugin.zsh

# Path to the C binary (adjust if needed)
ZSH_PLUGIN_DIR="${0:A:h}"
ZSH_PLUGIN_BIN="$ZSH_PLUGIN_DIR/hello"

hello_widget() {
  # Optionally pass $LBUFFER to the C program for more advanced use
  local output
  output="$($ZSH_PLUGIN_BIN)"
  LBUFFER+="$output"
}

zle -N hello_widget
bindkey '^x^h' hello_widget  # Ctrl-x Ctrl-h 