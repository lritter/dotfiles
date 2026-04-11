#!/bin/bash

track=$(osascript -e '
if application "Spotify" is running then
    tell application "Spotify"
        if player state is playing then
            return "󰝚 " & (get artist of current track) & " - " & (get name of current track)
        else
            return ""
        end if
    end tell
else
    return ""
end if
')

# Powerline characters (UTF-8 bytes for U+E0B6 and U+E0B4)
LEFT_CAP=$(printf '\xee\x82\xb6')
RIGHT_CAP=$(printf '\xee\x82\xb4')

if [[ -n "$track" ]]; then
    # Catppuccin green
    color="#8ec07c"
    text="#1e1e2e"
    # Output full tmux formatted string with Powerline endcaps
    echo "#[fg=${color},bg=default]${LEFT_CAP}#[fg=${text},bg=${color}]${track}#[fg=${color},bg=default]${RIGHT_CAP}"
fi
