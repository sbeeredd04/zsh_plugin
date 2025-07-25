# plugin.zsh — Simplified Zsh Autocomplete Plugin

# Path to the C autocomplete binary
ZSH_PLUGIN_DIR="${0:A:h}"
ZSH_AUTOCOMPLETE_BIN="${ZSH_PLUGIN_DIR}/autocomplete"

# Global state
typeset -g ZSH_CURRENT_PREFIX=""
typeset -g ZSH_HISTORY_INDEX=0
typeset -g ZSH_GHOST_TEXT=""
typeset -g ZSH_AUTOCOMPLETE_INITIALIZED=0

# — Helpers —

ensure_autocomplete_initialized() {
  if (( ZSH_AUTOCOMPLETE_INITIALIZED == 0 )); then
    get_zsh_history | "$ZSH_AUTOCOMPLETE_BIN" init >/dev/null 2>&1
    ZSH_AUTOCOMPLETE_INITIALIZED=1
  fi
}

get_zsh_history() {
  # extract commands from ~/.zsh_history
  awk -F';' '{ print $2 ? $2 : $1 }' ~/.zsh_history
}

# — Ghost‐text drawing ——

draw_ghost_suggestion() {
  # always redraw RBUFFER with the current ghost text
  RBUFFER="$ZSH_GHOST_TEXT"
  zle .redisplay
}

# hook before each redraw
zle -N zle-line-pre-redraw draw_ghost_suggestion

# — Core widgets —

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

self_insert_with_ghost() {
  zle .self-insert
  ZSH_GHOST_TEXT=$("$ZSH_AUTOCOMPLETE_BIN" ghost "$LBUFFER" 2>/dev/null) || ZSH_GHOST_TEXT=""
  draw_ghost_suggestion
}

backward_delete_char_with_ghost() {
  zle .backward-delete-char
  ZSH_GHOST_TEXT=$("$ZSH_AUTOCOMPLETE_BIN" ghost "$LBUFFER" 2>/dev/null) || ZSH_GHOST_TEXT=""
  draw_ghost_suggestion
}

autocomplete_navigation() {
  local dir=$1
  local buf=$LBUFFER

  # on first arrow-press, stash the prefix
  if [[ $buf != $ZSH_CURRENT_PREFIX ]]; then
    ZSH_CURRENT_PREFIX=$buf
    ZSH_HISTORY_INDEX=0
  fi

  ensure_autocomplete_initialized
  local res
  res="$("$ZSH_AUTOCOMPLETE_BIN" history "$ZSH_CURRENT_PREFIX" "$dir" "$ZSH_HISTORY_INDEX" 2>/dev/null)" || res=""

  if [[ -n $res ]]; then
    local entry="${res%|*}"
    ZSH_HISTORY_INDEX="${res##*|}"
    LBUFFER="$ZSH_CURRENT_PREFIX"
    ZSH_GHOST_TEXT="${entry#$ZSH_CURRENT_PREFIX}"
    draw_ghost_suggestion
  fi
}

autocomplete_up_widget()   { autocomplete_navigation up }
autocomplete_down_widget() { autocomplete_navigation down }

# — Register widgets —
zle -N accept_ghost_completion
zle -N self_insert_with_ghost
zle -N backward_delete_char_with_ghost
zle -N autocomplete_up_widget
zle -N autocomplete_down_widget

# — Key bindings —

# Right arrow → accept ghost
bindkey '\e[C' accept_ghost_completion

# Up / Down arrows → cycle suggestions
bindkey '\e[A' autocomplete_up_widget
bindkey '\e[B' autocomplete_down_widget

# Enter → accept the real line
bindkey '^M' accept-line

# Backspace → delete + refresh ghost
bindkey '^?' backward_delete_char_with_ghost

# All printable keys → insert + refresh ghost
for key in {a..z} {A..Z} {0..9} ' ' '!' '@' '#' '$' '%' '^' '&' '*' '(' ')' \
            '-' '_' '+' '=' '[' ']' '{' '}' '|' '\\' ':' ';' '"' "'" '<' '>' ',' '.' '/' '?'
do
  bindkey "$key" self_insert_with_ghost
done

# a no-op placeholder for zle
autocomplete :
