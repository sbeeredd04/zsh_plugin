# plugin.zsh - Simplified Zsh Autocomplete Plugin

# Path to the C binary
ZSH_PLUGIN_DIR="${0:A:h}"
ZSH_AUTOCOMPLETE_BIN="$ZSH_PLUGIN_DIR/autocomplete"

# Global state variables
typeset -g ZSH_CURRENT_PREFIX=""
typeset -g ZSH_HISTORY_INDEX=0
typeset -g ZSH_GHOST_TEXT=""
# One-time initialization flag
typeset -g ZSH_AUTOCOMPLETE_INITIALIZED=0

# Ensure the C autocomplete backend is initialized only once per session
ensure_autocomplete_initialized() {
    if [[ $ZSH_AUTOCOMPLETE_INITIALIZED -eq 0 ]]; then
        get_zsh_history | $ZSH_AUTOCOMPLETE_BIN init >/dev/null 2>&1
        ZSH_AUTOCOMPLETE_INITIALIZED=1
    fi
}

# Function to get zsh history
get_zsh_history() {
    # Handles both extended and simple Zsh history formats
    awk -F';' '{print $2 ? $2 : $1}' ~/.zsh_history
}

# Debug: Show how many lines are being piped to autocomplete
zsh_history_count() {
    get_zsh_history | wc -l
}

# Get and display ghost text for current buffer
update_ghost_text() {
    local current_buffer="$LBUFFER"
    
    # Don't show ghost text for very short prefixes
    if [[ ${#current_buffer} -lt 2 ]]; then
        ZSH_GHOST_TEXT=""
        return
    fi
    
    # Ensure backend initialized
    ensure_autocomplete_initialized

    # Get ghost text from C program (no history piped)
    local ghost_result
    ghost_result="$($ZSH_AUTOCOMPLETE_BIN ghost "$current_buffer" 2>/dev/null)"
    
    if [[ -n "$ghost_result" && "$ghost_result" != "$current_buffer" ]]; then
        # Extract the completion part (remove the prefix)
        local prefix_len=${#current_buffer}
        ZSH_GHOST_TEXT="${ghost_result:$prefix_len}"
        
        # Display ghost text in dim style (this would need terminal support)
        # For now, we'll just store it for right arrow acceptance
    else
        ZSH_GHOST_TEXT=""
    fi
}

# Widget for right arrow (accept ghost text completion)
accept_ghost_completion() {
    if [[ -n "$ZSH_GHOST_TEXT" ]]; then
        # Accept the ghost text completion
        LBUFFER+="$ZSH_GHOST_TEXT"
        CURSOR=${#LBUFFER}
        
        # Clear ghost text and get new completion
        ZSH_GHOST_TEXT=""
        update_ghost_text
    else
        # No ghost text, perform normal right arrow behavior
        if [[ $CURSOR -lt ${#BUFFER} ]]; then
            CURSOR=$((CURSOR + 1))
        fi
    fi
}

# Widget for up arrow (navigate filtered history)
autocomplete_up_widget() {
    local current_buffer="$LBUFFER"
    if [[ "$current_buffer" != "$ZSH_CURRENT_PREFIX" ]]; then
        ZSH_CURRENT_PREFIX="$current_buffer"
        ZSH_HISTORY_INDEX=0
    fi
    ensure_autocomplete_initialized
    local count=$(zsh_history_count)
    echo "[DEBUG] Up arrow: using backend trie with $count history lines (prefix='$current_buffer')" >&2
    local result
    result="$($ZSH_AUTOCOMPLETE_BIN history "$current_buffer" "up" "$ZSH_HISTORY_INDEX" 2>>/tmp/autocomplete_debug.log)"
    if [[ -n "$result" ]]; then
        local output="${result%|*}"
        local new_index="${result##*|}"
        ZSH_HISTORY_INDEX="$new_index"

        # Compute ghost text (output minus current prefix)
        if [[ "$output" == "$current_buffer"* ]]; then
            local suggestion="${output#$current_buffer}"
            ZSH_GHOST_TEXT="$suggestion"
        else
            ZSH_GHOST_TEXT=""
        fi

        # Keep buffer unchanged; cursor at end of prefix
        CURSOR=${#LBUFFER}
    else
        zle up-line-or-history
    fi
}

# Widget for down arrow (navigate filtered history)
autocomplete_down_widget() {
    local current_buffer="$LBUFFER"
    if [[ "$current_buffer" != "$ZSH_CURRENT_PREFIX" ]]; then
        ZSH_CURRENT_PREFIX="$current_buffer"
        ZSH_HISTORY_INDEX=0
    fi
    ensure_autocomplete_initialized
    local count=$(zsh_history_count)
    echo "[DEBUG] Down arrow: using backend trie with $count history lines (prefix='$current_buffer')" >&2
    local result
    result="$($ZSH_AUTOCOMPLETE_BIN history "$current_buffer" "down" "$ZSH_HISTORY_INDEX" 2>/dev/null)"
    if [[ -n "$result" ]]; then
        local output="${result%|*}"
        local new_index="${result##*|}"
        ZSH_HISTORY_INDEX="$new_index"

        # Compute ghost text suggestion
        if [[ "$output" == "$current_buffer"* ]]; then
            local suggestion="${output#$current_buffer}"
            ZSH_GHOST_TEXT="$suggestion"
        else
            ZSH_GHOST_TEXT=""
        fi

        CURSOR=${#LBUFFER}
    else
        zle down-line-or-history
    fi
}

# Widget for regular typing (updates ghost text)
self_insert_with_ghost() {
    # Perform normal character insertion
    zle self-insert
    
    # Reset prefix tracking since buffer changed
    ZSH_CURRENT_PREFIX=""
    ZSH_HISTORY_INDEX=0
    
    # Update ghost text
    update_ghost_text
}

# Widget for backspace (updates ghost text)
backward_delete_char_with_ghost() {
    # Perform normal backspace
    zle backward-delete-char
    
    # Reset prefix tracking since buffer changed
    ZSH_CURRENT_PREFIX=""
    ZSH_HISTORY_INDEX=0
    
    # Update ghost text
    update_ghost_text
}

# Widget for enter key (execute command and update usage)
accept_line_with_update() {
    local command_to_execute="$LBUFFER"
    
    # Update command usage statistics if we have a command
    if [[ -n "$command_to_execute" ]]; then
        ensure_autocomplete_initialized
        ($ZSH_AUTOCOMPLETE_BIN update "" "$command_to_execute" >/dev/null 2>&1 &)
    fi
    
    # Reset state for new command
    ZSH_CURRENT_PREFIX=""
    ZSH_HISTORY_INDEX=0
    ZSH_GHOST_TEXT=""
    
    # Execute the command
    zle accept-line
}

# Register widgets
zle -N autocomplete_up_widget
zle -N autocomplete_down_widget  
zle -N accept_ghost_completion
zle -N self_insert_with_ghost
zle -N backward_delete_char_with_ghost
zle -N accept_line_with_update

# Bind keys to widgets
bindkey '^[[A' autocomplete_up_widget     # Up arrow
bindkey '^[[B' autocomplete_down_widget   # Down arrow
bindkey '^[[C' accept_ghost_completion    # Right arrow
bindkey '^[OA' autocomplete_up_widget     # Up arrow (alternative)
bindkey '^[OB' autocomplete_down_widget   # Down arrow (alternative)
bindkey '^[OC' accept_ghost_completion    # Right arrow (alternative)

# Bind enter key to update usage
bindkey '^M' accept_line_with_update      # Enter key

# Bind typing to update ghost text
bindkey '^?' backward_delete_char_with_ghost  # Backspace

# Bind regular characters to update ghost text
for char in {a..z} {A..Z} {0..9} ' ' '-' '_' '=' '+' '[' ']' '{' '}' '|' '\' ':' ';' '"' "'" '<' '>' ',' '.' '?' '/' '~' '`' '!' '@' '#' '$' '%' '^' '&' '*' '(' ')'; do
    bindkey "$char" self_insert_with_ghost
done

echo "Zsh Autocomplete Plugin loaded successfully"
echo "Features: Ghost text completion, Trie-based history navigation, Persistent storage"