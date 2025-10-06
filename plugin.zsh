# plugin.zsh — Simplified Zsh Autocomplete Plugin

# Prevent double-loading to avoid widget redefinition errors
if [[ -n ${ZSH_AUTOCOMPLETE_PLUGIN_LOADED+x} ]]; then
  return 0
fi
typeset -g ZSH_AUTOCOMPLETE_PLUGIN_LOADED=1

autoload -Uz colors && colors

# — Path to the C autocomplete binary —
ZSH_PLUGIN_DIR="${0:A:h}"
ZSH_AUTOCOMPLETE_BIN="${ZSH_PLUGIN_DIR}/autocomplete"

# — Global state —
typeset -g ZSH_CURRENT_PREFIX=""        # the prefix we're cycling through
typeset -g ZSH_HISTORY_INDEX=-1         # index in the history cycle (-1 = original)
typeset -g ZSH_GHOST_TEXT=""            # the suffix suggestion
typeset -g ZSH_AUTOCOMPLETE_INITIALIZED=0

# — Helpers — 

# Initialize the trie from ~/.zsh_history the first time it's needed
ensure_autocomplete_initialized() {
  if (( ZSH_AUTOCOMPLETE_INITIALIZED == 0 )); then
    get_zsh_history | "$ZSH_AUTOCOMPLETE_BIN" init >/dev/null 2>&1
    ZSH_AUTOCOMPLETE_INITIALIZED=1
  fi
}

# Extract raw commands from zsh history file
get_zsh_history() {
  awk -F';' '{ print $2 ? $2 : $1 }' ~/.zsh_history
}

# — Ghost‐text drawing — 

# Draw the current ghost suggestion to the right of the cursor
draw_ghost_suggestion() {
  RBUFFER="$ZSH_GHOST_TEXT"
  
  # Style the ghost text with dim gray color
  if [[ -n $ZSH_GHOST_TEXT ]]; then
    region_highlight=("$#LBUFFER $(( $#LBUFFER + $#ZSH_GHOST_TEXT )) fg=8")
  else
    region_highlight=()
  fi
  
  zle .redisplay
}
zle -N zle-line-pre-redraw draw_ghost_suggestion

# — Core widgets — 

# Accept the ghost suggestion into the buffer
accept_ghost_completion() {
  if [[ -n $ZSH_GHOST_TEXT ]]; then
    LBUFFER+="$ZSH_GHOST_TEXT"
    CURSOR=${#LBUFFER}
    ZSH_GHOST_TEXT=""
    draw_ghost_suggestion
  else
    zle forward-char
  fi
}

# Insert a character, then update ghost text from trie
self_insert_with_ghost() {
  zle .self-insert
  local full
  full=$("$ZSH_AUTOCOMPLETE_BIN" ghost "$LBUFFER" 2>/dev/null) || full=""
  if [[ $full == "$LBUFFER"* ]]; then
    ZSH_GHOST_TEXT=${full#"$LBUFFER"}
  else
    ZSH_GHOST_TEXT=""
  fi
  draw_ghost_suggestion
}

# Delete a character, then update ghost text from trie
backward_delete_char_with_ghost() {
  zle .backward-delete-char
  local full
  full=$("$ZSH_AUTOCOMPLETE_BIN" ghost "$LBUFFER" 2>/dev/null) || full=""
  if [[ $full == "$LBUFFER"* ]]; then
    ZSH_GHOST_TEXT=${full#"$LBUFFER"}
  else
    ZSH_GHOST_TEXT=""
  fi
  draw_ghost_suggestion
}

# Cycle through history‐based suggestions (up/down)
autocomplete_navigation() {
  local dir=$1 buf=$LBUFFER
  # on first arrow‐press, stash the current buffer as prefix
  if [[ $buf != $ZSH_CURRENT_PREFIX ]]; then
    ZSH_CURRENT_PREFIX=$buf
    ZSH_HISTORY_INDEX=-1
  fi
  ensure_autocomplete_initialized
  local res entry
  res=$("$ZSH_AUTOCOMPLETE_BIN" history "$ZSH_CURRENT_PREFIX" "$dir" "$ZSH_HISTORY_INDEX" 2>/dev/null) || res=""
  if [[ -n $res ]]; then
    entry="${res%|*}"
    ZSH_HISTORY_INDEX="${res##*|}"
    LBUFFER="$ZSH_CURRENT_PREFIX"
    ZSH_GHOST_TEXT="${entry#$ZSH_CURRENT_PREFIX}"
    draw_ghost_suggestion
  fi
}

# When Enter is pressed: update the trie with only the typed part,
# then accept the line (ghost text is never auto–appended)
accept_line_and_update() {
  local cmd=$LBUFFER
  if [[ -n $cmd ]]; then
    ensure_autocomplete_initialized
    "$ZSH_AUTOCOMPLETE_BIN" update "" "$cmd" >/dev/null 2>&1
  fi
  # Reset navigation state so next history navigation starts fresh
  ZSH_GHOST_TEXT=""
  ZSH_CURRENT_PREFIX=""
  ZSH_HISTORY_INDEX=-1
  zle accept-line
}

# — Tab → complete‑or‑accept‑ghost widget —
# If ghost text exists, Tab accepts it; otherwise do normal file/word completion,
# then immediately fetch & display a new ghost suggestion.
complete-or-ghost() {
  if [[ -n $ZSH_GHOST_TEXT ]]; then
    accept_ghost_completion
  else
    zle complete-word
    local full
    full=$("$ZSH_AUTOCOMPLETE_BIN" ghost "$BUFFER" 2>/dev/null) || full=""
    if [[ $full == "$BUFFER"* ]]; then
      ZSH_GHOST_TEXT=${full#"$BUFFER"}
      draw_ghost_suggestion
    fi
  fi
}

# Delete word backward (Option+Backspace) with ghost text update
backward_delete_word_with_ghost() {
  zle .backward-delete-word
  local full
  full=$("$ZSH_AUTOCOMPLETE_BIN" ghost "$LBUFFER" 2>/dev/null) || full=""
  if [[ $full == "$LBUFFER"* ]]; then
    ZSH_GHOST_TEXT=${full#"$LBUFFER"}
  else
    ZSH_GHOST_TEXT=""
  fi
  draw_ghost_suggestion
}

# Delete entire line backward (Cmd+Backspace) with ghost text update
backward_kill_line_with_ghost() {
  zle .backward-kill-line
  local full
  full=$("$ZSH_AUTOCOMPLETE_BIN" ghost "$LBUFFER" 2>/dev/null) || full=""
  if [[ $full == "$LBUFFER"* ]]; then
    ZSH_GHOST_TEXT=${full#"$LBUFFER"}
  else
    ZSH_GHOST_TEXT=""
  fi
  draw_ghost_suggestion
}

# — Register widgets BEFORE binding keys — 
# This must happen before any bindkey commands to avoid "undefined-key" errors
zle -N accept_ghost_completion
zle -N self_insert_with_ghost
zle -N backward_delete_char_with_ghost
zle -N backward_delete_word_with_ghost
zle -N backward_kill_line_with_ghost
autocomplete_up_widget()   { autocomplete_navigation up }
autocomplete_down_widget() { autocomplete_navigation down }
zle -N autocomplete_up_widget
zle -N autocomplete_down_widget
zle -N accept_line_and_update
zle -N complete-or-ghost

# — Key bindings — 
# Up/Down → cycle history suggestions
bindkey '\e[A' autocomplete_up_widget
bindkey '\e[B' autocomplete_down_widget

# Left/Right → default cursor movement
bindkey '\e[D' backward-char
bindkey '\e[C' forward-char

# Tab → complete or accept ghost suggestion
bindkey '^I' complete-or-ghost

# Enter → update trie with typed text, then accept
bindkey '^M' accept_line_and_update

# Backspace → delete + refresh ghost
bindkey '^?' backward_delete_char_with_ghost

# Option+Backspace (Alt+Backspace) → delete word backward
bindkey '^[^?' backward_delete_word_with_ghost
bindkey '^[^H' backward_delete_word_with_ghost

# Cmd+Backspace (macOS) → delete to beginning of line
# On macOS, Cmd+Backspace often sends ^U
bindkey '^U' backward_kill_line_with_ghost

# Printable keys → insert + refresh ghost
for key in {a..z} {A..Z} {0..9} ' ' '!' '@' '#' '$' '%' '^' '&' '*' '(' ')' \
            '-' '_' '+' '=' '[' ']' '{' '}' '|' '\\' ':' ';' '"' "'" '<' '>' ',' '.' '/' '?'
do
  bindkey "$key" self_insert_with_ghost
done
