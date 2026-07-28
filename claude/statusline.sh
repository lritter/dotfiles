#!/usr/bin/env bash
input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd')
model=$(echo "$input" | jq -r '.model.display_name // "unknown"')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
five=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
gitstatus=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)
dirty=''
[ -n "$gitstatus" ] && dirty=' '
prefix="${1:-}"
rst='\033[0m'
fg0='\033[38;2;251;241;199m'
obg='\033[48;2;214;93;14m'
ofg='\033[38;2;214;93;14m'
bbg='\033[48;2;69;133;136m'
bfg='\033[38;2;69;133;136m'
dbg='\033[48;2;60;56;54m'
dfg='\033[38;2;60;56;54m'
if [ -n "$prefix" ]; then
  if [ -n "$branch" ]; then
    printf "${obg}${fg0} ${prefix} ${ofg}${bbg}\xee\x82\xb0"
  else
    printf "${obg}${fg0} ${prefix} ${ofg}${dbg}\xee\x82\xb0"
  fi
fi
if [ -n "$branch" ]; then
  printf "${bbg}${fg0} \xee\x82\xa0 ${branch}${dirty}"
  printf "${bfg}${dbg}\xee\x82\xb0"
elif [ -z "$prefix" ]; then
  printf "${dbg}"
fi
extra=''
[ -n "$used" ] && extra="$(printf '%.0f' "$used")%% ctx"
[ -n "$five" ] && extra="${extra}${extra:+  }5h:$(printf '%.0f' "$five")%%"
[ -n "$week" ] && extra="${extra}${extra:+  }7d:$(printf '%.0f' "$week")%%"
[ -n "$extra" ] && printf "${fg0}${dbg} ${extra}  "
printf "${fg0}${dbg}${model} "
printf "${dfg}\033[49m\xee\x82\xb0${rst}"
