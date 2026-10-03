#!/usr/bin/env bash
# tmux-claude plugin entry. Load from ~/.tmux.conf:
#   run-shell ~/path/to/tmux-claude/tmux-claude.tmux        (manual)
#   set -g @plugin 'helinwang/tmux-claude'              (TPM)
# Options (set before the run-shell / TPM line):
#   @tmux_claude_key_win   w    fuzzy window picker
#   @tmux_claude_key_grep  g    grep every pane's scrollback
#   @tmux_claude_key_last  b    jump to previously visited window (across sessions)
#   @tmux_claude_key_tree  W    native choose-tree without duplicated title
#   @tmux_claude_rename    on   window name = Claude Code task title
#   @tmux_claude_status    off  color status-bar windows by state (red needs you, yellow busy, magenta draft), counts on the right
dir=$(cd "$(dirname "$0")" && pwd)
opt() { local v; v=$(tmux show -gqv "$1"); printf '%s' "${v:-$2}"; }

tmux bind "$(opt @tmux_claude_key_win w)"  display-popup -E -B -w 100% -h 100% -e "TMUX_CLAUDE_CLIENT=#{client_tty}" "$dir/bin/tmux-claude-win"
tmux bind "$(opt @tmux_claude_key_grep g)" display-popup -E -w 90% -h 80% -e "TMUX_CLAUDE_CLIENT=#{client_tty}" "$dir/bin/tmux-claude-grep"
tmux bind "$(opt @tmux_claude_key_last b)" run-shell -b "TMUX_CLAUDE_CLIENT=#{client_tty} $dir/bin/tmux-claude-win --last"
tmux bind "$(opt @tmux_claude_key_tree W)" choose-tree -Zw -F '#{?pane_format,#{pane_current_command}#{?pane_active,*,}:#{pane_title},#{?window_format,#{window_name}#{window_flags},#{session_windows} windows#{?session_attached, (attached),}}}'

# last-visited stamp, used for picker order and the back key
tmux set -g focus-events on
tmux set-hook -g pane-focus-in 'run-shell -b "tmux set -w -t #{window_id} @visited $(date +%s)"'

[ "$(opt @tmux_claude_rename on)" = on ] && tmux set -gw automatic-rename-format '#{?pane_title,#{s/^✳ //:pane_title},#{pane_current_command}}'

if [ "$(opt @tmux_claude_status off)" = on ]; then
  tmux set -g window-status-format '#{?#{==:#{@state},ask},#[fg=white#,bg=red],}#{?#{==:#{@state},busy},#[fg=black#,bg=yellow],}#{?#{==:#{@state},draft},#[fg=white#,bg=magenta],}#I:#{=14:window_name}#{?window_flags,#{window_flags}, }#[default]'
  tmux set -g window-status-current-format '#[bold]#I:#{=14:window_name}#{?window_flags,#{window_flags}, }#[default]'
  tmux set -g window-status-current-style reverse
  tmux set -g status-right-length 60
  tmux set -g status-right "#($dir/bin/tmux-claude-state --set --counts) %H:%M"
fi
exit 0
