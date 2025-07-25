# plugin.zsh — Simplified Zsh Autocomplete Plugin

# — Path to the C autocomplete binary —
ZSH_PLUGIN_DIR="${0:A:h}"
ZSH_AUTOCOMPLETE_BIN="${ZSH_PLUGIN_DIR}/autocomplete"

# — Global state —
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
  # pull commands out of ~/.zsh_history
  awk -F';' '{ print $2 ? $2 : $1 }' ~/.zsh_history
}

# — Ghost‑text drawing —
draw_ghost_suggestion() {
  RBUFFER="$ZSH_GHOST_TEXT"
  zle .redisplay
}
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

  # full suggestion from the C‑binary
  local full
  full=$("$ZSH_AUTOCOMPLETE_BIN" ghost "$LBUFFER" 2>/dev/null) || full=""

  # strip off what you've already typed
  if [[ $full == "$LBUFFER"* ]]; then
    ZSH_GHOST_TEXT=${full#"$LBUFFER"}
  else
    ZSH_GHOST_TEXT=""
  fi

  draw_ghost_suggestion
}

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

autocomplete_navigation() {
  local dir=$1 buf=$LBUFFER

  # stash prefix on first arrow‐press
  if [[ $buf != $ZSH_CURRENT_PREFIX ]]; then
    ZSH_CURRENT_PREFIX=$buf
    ZSH_HISTORY_INDEX=0
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

# wrap ↩ so we update the trie then accept
accept_line_and_update() {
  local cmd=$LBUFFER
  if [[ -n $cmd ]]; then
    ensure_autocomplete_initialized
    "$ZSH_AUTOCOMPLETE_BIN" update "" "$cmd" >/dev/null 2>&1
  fi
  zle accept-line
}

# — Register widgets —

zle -N accept_ghost_completion
zle -N self_insert_with_ghost
zle -N backward_delete_char_with_ghost

# define and register arrow‑key widgets
autocomplete_up_widget()   { autocomplete_navigation up }
autocomplete_down_widget() { autocomplete_navigation down }
zle -N autocomplete_up_widget
zle -N autocomplete_down_widget

zle -N accept_line_and_update

# — Key bindings —

# Right → accept ghost
bindkey '\e[C' accept_ghost_completion

# Up/Down → cycle suggestions
bindkey '\e[A' autocomplete_up_widget
bindkey '\e[B' autocomplete_down_widget

# Left → real cursor‑move
bindkey '\e[D' backward-char

# ↩ → update + accept
bindkey '^M' accept_line_and_update

# Backspace → delete + refresh ghost
bindkey '^?' backward_delete_char_with_ghost

# All printable chars → insert + refresh ghost
for key in {a..z} {A..Z} {0..9} ' ' '!' '@' '#' '$' '%' '^' '&' '*' '(' ')' \
            '-' '_' '+' '=' '[' ']' '{' '}' '|' '\\' ':' ';' '"' "'" '<' '>' ',' '.' '/' '?'
do
  bindkey "$key" self_insert_with_ghost
done
