#!/usr/bin/env bash
# Builds a throwaway tmux server (socket "tmux-claude-demo") full of fake Claude Code windows,
# runs the pickers inside it, and writes demo/picker.png + demo/grep.png. Never touches your real server.
set -e
here=$(cd "$(dirname "$0")" && pwd); root=$(dirname "$here")
T="tmux -L tmux-claude-demo -f /dev/null"
$T kill-server 2>/dev/null || true
fc="$here/fake-claude.sh"
mk() { # session window-title state body...
  local s=$1 t=$2 st=$3; shift 3
  if $T has-session -t "$s" 2>/dev/null; then $T new-window -d -t "$s" "$fc" "$t" "$st" "$@"
  else $T new-session -d -s "$s" -x 110 -y 32 "$fc" "$t" "$st" "$@"; fi
}
mk api   "Rate limiter for public API"      busy  "● Added token bucket in middleware/ratelimit.go" "  Running go test ./... (3 packages)"
mk api   "Fix flaky upload test"            draft "● The test races the temp dir cleanup. Patched with t.Cleanup." "  12 passed, 0 failed."
mk api   "Migrate sessions table"           idle  "● Migration 0042 written. Dry run against staging hit the 30s statement timeout," "  retry with a smaller batch size?"
mk web   "Dark mode toggle"                 idle  "● Done. Theme persists in localStorage, respects prefers-color-scheme."
mk web   "Checkout page timeout errors"     busy  "● Reproduced: fetch to /api/cart hits the 10s client timeout with >50 items." "  Profiling the serializer now."
mk web   "Bundle size audit"                ask   "● lodash full import in 3 files. Switching to lodash-es saves 71 KB." "" "  Bash(npm uninstall lodash && npm install lodash-es)"
mk infra "Terraform drift in prod VPC"      idle  "● Drift: 2 security group rules added by hand. Plan to import them attached."
mk infra "Alert on p99 latency"             busy  "● Writing the PromQL rule and a runbook link. Timeout threshold 800ms."
mk infra "Rotate database credentials"      idle  "● Rotated. Old password revoked, 0 failed connections in the last 10 min."
sleep 1
$T run-shell "$root/tmux-claude.tmux"
now=$(date +%s); i=0
for w in infra:2 web:1 api:0 api:2 web:0 infra:0 api:1 web:2 infra:1; do
  $T set -w -t "$w" @visited $((now - i * 97)); $T set -w -t "$w" automatic-rename off \; set -w -t "$w" automatic-rename on; i=$((i+1))
done
sleep 1
shoot() { # name cmd keys...
  local name=$1 cmd=$2; shift 2
  $T new-window -t api -n tmux-claude "$cmd"; sleep 1.5
  for k in "$@"; do $T send-keys -t api:tmux-claude "$k"; sleep 0.8; done
  $T capture-pane -p -e -t api:tmux-claude | sed -e 's/[[:space:]]*$//' | python3 "$here/ansi2png.py" "$here/$name.png"
  $T kill-window -t api:tmux-claude
}
shoot picker "$root/bin/tmux-claude-win"
shoot grep   "$root/bin/tmux-claude-grep" "timeout"
$T kill-server
echo "wrote $here/picker.png $here/grep.png"
