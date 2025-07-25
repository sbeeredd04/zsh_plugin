# plugin.zsh

# Path to the C binary (adjust if needed)
ZSH_PLUGIN_DIR="${0:A:h}"
ZSH_AUTOCOMPLETE_BIN="$ZSH_PLUGIN_DIR/autocomplete"

autocomplete_widget() {
  # Optionally pass $LBUFFER to the C program for more advanced use
  local output
  output="$($ZSH_AUTOCOMPLETE_BIN)"
  LBUFFER+="$output"
}

zle -N autocomplete_widget
bindkey '^[[A' autocomplete_widget  # up arrow for navigation
bindkey '^[[B' autocomplete_widget  # down arrow for navigation