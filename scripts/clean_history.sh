#!/bin/bash

# Script to remove history entries over 1200 characters from zsh history

HISTFILE="${HISTFILE:-$HOME/.zsh_history}"
TEMP_FILE="/tmp/zsh_history_cleaned_$$"
MAX_LENGTH=256

if [ ! -f "$HISTFILE" ]; then
    echo "History file not found: $HISTFILE"
    exit 1
fi

# Create backup
cp "$HISTFILE" "${HISTFILE}.backup.$(date +%Y%m%d_%H%M%S)"
echo "Created backup: ${HISTFILE}.backup.$(date +%Y%m%d_%H%M%S)"

# Process history file
# zsh history format: ": timestamp:0;command"
awk -v max_len="$MAX_LENGTH" '
BEGIN { RS="\n"; ORS="" }
{
    if ($0 ~ /^: [0-9]+:[0-9]+;/) {
        # Extract command part (after the timestamp)
        match($0, /^: [0-9]+:[0-9]+;/)
        cmd = substr($0, RLENGTH + 1)
        
        # Check length and print if under limit
        if (length(cmd) <= max_len) {
            print $0 "\n"
        } else {
            removed++
        }
    } else {
        # Handle multi-line commands or malformed entries
        if (length($0) <= max_len) {
            print $0 "\n"
        }
    }
}
END {
    if (removed > 0) {
        print "Removed " removed " entries over " max_len " characters\n" > "/dev/stderr"
    }
}
' "$HISTFILE" > "$TEMP_FILE"

# Replace original file
if [ -s "$TEMP_FILE" ]; then
    mv "$TEMP_FILE" "$HISTFILE"
    echo "History cleaned successfully!"
else
    echo "Error: Cleaned file is empty. Original file preserved."
    rm -f "$TEMP_FILE"
    exit 1
fi
