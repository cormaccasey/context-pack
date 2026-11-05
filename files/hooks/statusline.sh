#!/bin/bash
# Shows "ctx NN%" in Claude Code's status line and records it so the
# context guard hook knows when to save to ALIVE.
input=$(cat)
pct=$(echo "$input" | jq -r '(.context_window.used_percentage) // ((.context_window.context_window_size // 0) as $s | (.context_window.current_usage // null) as $u | if $u != null and $s > 0 then ((($u.input_tokens // 0) + ($u.cache_creation_input_tokens // 0) + ($u.cache_read_input_tokens // 0)) * 100 / $s) else 0 end)')
sid=$(echo "$input" | jq -r '.session_id // empty' | tr -c 'A-Za-z0-9._-\n' '_')
[ -n "$sid" ] && mkdir -p ~/.claude/state/ctx && printf '%.0f\n' "${pct:-0}" > ~/.claude/state/ctx/$sid.pct
printf 'ctx %.0f%%' "${pct:-0}"
