#!/bin/bash
# Commits and pushes the brain to its private GitHub repo. Runs daily via launchd.
BRAIN="$(cat "$HOME/.config/context-pack/brain-dir" 2>/dev/null)"
[ -d "$BRAIN/.git" ] || exit 0
cd "$BRAIN" || exit 0
git add -A
git diff --cached --quiet || git commit -q -m "Brain backup $(date '+%Y-%m-%d %H:%M')"
git push -q 2>/dev/null || true
