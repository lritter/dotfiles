#!/usr/bin/env bash
# Run "$@" in a Ghostty terminal, then close that terminal when it exits.
# Windows created via Ghostty's AppleScript `new window` always wait for a
# keypress after the command exits (wait-after-command is ignored there), so we
# close our own terminal by tty. Used by claude-file-picker.sh (ctrl-o).
#
# The close must happen AFTER this process is gone: a plain background job is
# killed with the terminal, and closing while a process still runs raises
# Ghostty's "close terminal?" confirmation. So fork a setsid'd (fully detached)
# helper that waits a beat, then asks Ghostty to close the terminal.
"$@"
t="$(tty)"
/usr/bin/perl -MPOSIX -e '
  fork and exit; POSIX::setsid();
  open STDIN, "</dev/null"; open STDOUT, ">/dev/null"; open STDERR, ">/dev/null";
  select undef, undef, undef, 0.3;
  exec "osascript", "-e",
    "tell application \"Ghostty\" to close (first terminal whose tty is \"$ARGV[0]\")";
' "$t"
