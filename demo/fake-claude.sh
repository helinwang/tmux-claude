#!/usr/bin/env bash
# Draws a fake Claude Code screen for screenshots. usage: fake-claude.sh "<title>" ask|busy|idle|draft [body-lines...]
title=$1; state=$2; shift 2
printf '\033]2;✳ %s\007' "$title"            # pane title, like Claude Code sets it
printf '\n'
for l in "$@"; do printf '  %s\n' "$l"; done
printf '\n'
if [ "$state" = ask ]; then
  printf '  Do you want to proceed?\n  ❯ 1. Yes\n    2. Yes, and don'"'"'t ask again for this command\n    3. No\n\n  Enter to select · Esc to cancel\n'
  exec sleep infinity
fi
sep=$(printf '─%.0s' $(seq 1 70))
printf '%s\n' "$sep"
case $state in
  draft) printf '❯ also add a retry around the flaky upload step\n' ;;
  *)     printf '❯ \n' ;;
esac
printf '%s\n' "$sep"
case $state in
  busy) printf '  accept edits on (shift+tab to cycle) · esc to interrupt\n' ;;
  *)    printf '  accept edits on (shift+tab to cycle)\n' ;;
esac
exec sleep infinity
