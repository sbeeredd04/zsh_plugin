# plugin.zsh - Zsh Autocomplete Plugin with Real History

# Path to the C binary
ZSH_PLUGIN_DIR="${0:A:h}"
ZSH_AUTOCOMPLETE_BIN="$ZSH_PLUGIN_DIR/autocomplete"

# Global variable to track history navigation state
typeset -g ZSH_HISTORY_INDEX=0

# Function to get zsh history
get_zsh_history() {
    # Use fc to get the full history, reverse it so newest is first
    # Remove the line numbers and just get the commands
    # Use tail -r for macOS compatibility (instead of tac)
    fc -l 1 | awk '{$1=""; print substr($0,2)}' | tail -r
}

# Widget for up arrow (previous/older command)
autocomplete_up_widget() {
    local output
    local result
    local new_index
    
    # Pass current buffer, direction, and current index to C program
    result="$(get_zsh_history | $ZSH_AUTOCOMPLETE_BIN "$LBUFFER" "up" "$ZSH_HISTORY_INDEX")"
    
    if [[ -n "$result" ]]; then
        # Parse the result (command|index)
        output="${result%|*}"     # Everything before the last |
        new_index="${result##*|}" # Everything after the last |
        
        # Update global index
        ZSH_HISTORY_INDEX="$new_index"
        
        # Replace entire line with history entry
        LBUFFER="$output"
        RBUFFER=""
        # Move cursor to end of line
        CURSOR=${#LBUFFER}
    fi
}

# Widget for down arrow (next/newer command)
autocomplete_down_widget() {
    local output
    local result
    local new_index
    
    # Pass current buffer, direction, and current index to C program
    result="$(get_zsh_history | $ZSH_AUTOCOMPLETE_BIN "$LBUFFER" "down" "$ZSH_HISTORY_INDEX")"
    
    if [[ -n "$result" ]]; then
        # Parse the result (command|index)
        output="${result%|*}"     # Everything before the last |
        new_index="${result##*|}" # Everything after the last |
        
        # Update global index
        ZSH_HISTORY_INDEX="$new_index"
        
        # Replace entire line with history entry
        LBUFFER="$output"
        RBUFFER=""
        # Move cursor to end of line
        CURSOR=${#LBUFFER}
    fi
}

# Reset index when user starts typing a new command
reset_history_index() {
    ZSH_HISTORY_INDEX=0
}

# Register the widgets
zle -N autocomplete_up_widget
zle -N autocomplete_down_widget
zle -N reset_history_index

# Bind to up and down arrow keys
# Note: This overrides the default zsh history navigation
bindkey '^[[A' autocomplete_up_widget    # Up arrow
bindkey '^[[B' autocomplete_down_widget  # Down arrow

# Alternative bindings for different terminal types
bindkey '^[OA' autocomplete_up_widget    # Up arrow (alternative)
bindkey '^[OB' autocomplete_down_widget  # Down arrow (alternative)

# Reset index when user executes a command or starts fresh
bindkey '^M' reset_history_index  # Enter key - reset for new command