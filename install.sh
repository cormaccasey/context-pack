#!/bin/bash
# Context Pack installer (macOS)
# Sets up: Warp + Claude Code + an ALIVE second brain (Obsidian vault) + the
# context hooks that save your work into it, + optional private GitHub backup.
#
#   curl -fsSL https://raw.githubusercontent.com/cormaccasey/context-pack/main/install.sh | bash
#
# Safe to re-run: it skips what's already there and never overwrites your notes.

set -u
REPO="${CONTEXT_PACK_REPO:-cormaccasey/context-pack}"
CLAUDE_DIR="$HOME/.claude"
TTY=/dev/tty

say()  { printf '\n\033[1;35m▸ %s\033[0m\n' "$*"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; }
TEST="${CP_TEST:-}"   # CP_TEST=1: dry run for testing (defaults, skips installs and GitHub)
ask()  { # ask "Question" "default" -> echoes answer
  [ -n "$TEST" ] && { echo "$2"; return; }
  local a; printf '  %s [%s]: ' "$1" "$2" > $TTY; read -r a < $TTY; echo "${a:-$2}"; }
confirm() { case "$(ask "$1 (y/n)" "${2:-y}")" in [Yy]*) return 0;; *) return 1;; esac; }

[ "$(uname)" = "Darwin" ] || { echo "This installer is for macOS."; exit 1; }

# ── Find the pack files (local clone, or download the repo) ───────────────
HERE="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"
if [ -n "$HERE" ] && [ -d "$HERE/files" ]; then
  PACK="$HERE"
else
  PACK="$(mktemp -d)/context-pack"; mkdir -p "$PACK"
  curl -fsSL "https://github.com/$REPO/archive/refs/heads/main.tar.gz" | tar -xz -C "$PACK" --strip-components=1 \
    || { echo "Couldn't download the pack from github.com/$REPO"; exit 1; }
fi
F="$PACK/files"

cat <<'EOF'

  ┌──────────────────────────────────────────────┐
  │   Context Pack: context, context, context    │
  └──────────────────────────────────────────────┘
  Takes about 10 minutes. You'll be asked for your Mac password once
  (for Homebrew) and to sign in to Claude and, optionally, GitHub.
EOF

NAME="$(ask "Your first name" "$(id -F 2>/dev/null | awk '{print $1}')")"
BRAIN="$(ask "Where should your brain live" "$HOME/Documents/${NAME}'s Brain")"
BRAIN="${BRAIN/#\~/$HOME}"
ALIVE="$BRAIN/ALIVE"

# ── 1. Tools ──────────────────────────────────────────────────────────────
say "1/6 Tools (Homebrew, git, GitHub CLI, jq, Node, Warp, Obsidian)"
if [ -z "$TEST" ]; then
if ! command -v brew >/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" < $TTY
fi
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
[ -x /usr/local/bin/brew ] && eval "$(/usr/local/bin/brew shellenv)"
command -v brew >/dev/null || { echo "Homebrew didn't install. Fix that and re-run."; exit 1; }
for p in git gh jq node python3; do
  if command -v "$p" >/dev/null; then ok "$p"; else brew install "${p/python3/python}" >/dev/null && ok "$p installed"; fi
done
[ -d /Applications/Warp.app ] && ok "Warp" || { brew install --cask warp >/dev/null && ok "Warp installed"; }
[ -d /Applications/Obsidian.app ] && ok "Obsidian" || { brew install --cask obsidian >/dev/null && ok "Obsidian installed"; }
fi

# ── 2. Claude Code ────────────────────────────────────────────────────────
say "2/6 Claude Code"
export PATH="$HOME/.local/bin:$PATH"
if [ -n "$TEST" ]; then ok "(test: skipped)"
elif command -v claude >/dev/null; then ok "Claude Code $(claude --version 2>/dev/null)"
else curl -fsSL https://claude.ai/install.sh | bash && ok "Claude Code installed"; fi
grep -q '.local/bin' "$HOME/.zshrc" 2>/dev/null || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"

# ── 3. The brain (ALIVE world inside an Obsidian vault) ───────────────────
say "3/6 Your brain at: $BRAIN"
mkdir -p "$ALIVE"/{01_Archive,02_Life,03_Inbox,04_Ventures,05_Experiments,.alive}
mkdir -p "$ALIVE/02_Life/learning"
if [ ! -f "$BRAIN/Home.md" ]; then
  cat > "$BRAIN/Home.md" <<EOF
# ${NAME}'s Brain

Start here. Everything lives in \`ALIVE/\`, organised as walnuts.

- **02_Life/**: personal. Goals, people, learning.
- **03_Inbox/**: buffer. New stuff lands here, then gets routed.
- **04_Ventures/**: businesses, clients, products.
- **05_Experiments/**: ideas and prototypes.
- **01_Archive/**: finished things.

## Walnuts
<!-- Claude adds a line here for every new walnut. -->
EOF
fi
mkdir -p "$HOME/.config/alive" "$HOME/.config/context-pack"
printf '%s\n' "$ALIVE" > "$HOME/.config/alive/world-root"
printf '%s\n' "$BRAIN" > "$HOME/.config/context-pack/brain-dir"
ok "Brain folders ready (open it in Obsidian: Open folder as vault → $BRAIN)"

# ── 4. ALIVE plugin ───────────────────────────────────────────────────────
say "4/6 ALIVE plugin"
if [ -n "$TEST" ]; then ok "(test: skipped)"
elif claude plugin marketplace add https://github.com/stackwalnuts/alive.git >/dev/null 2>&1; [ 1 ] && claude plugin install alive@alivecontext -y >/dev/null 2>&1 || claude plugin list 2>/dev/null | grep -q alive; then ok "ALIVE installed"
else warn "Couldn't install ALIVE automatically. In Claude, run: /plugin install alive@alivecontext"; fi

# ── 5. Hooks, skill, status line, rules ───────────────────────────────────
say "5/6 Context hooks and rules"
mkdir -p "$CLAUDE_DIR/hooks" "$CLAUDE_DIR/skills/alive-presave" "$CLAUDE_DIR/state/ctx"
cp "$F/hooks/alive-context-guard.sh" "$F/hooks/statusline.sh" "$CLAUDE_DIR/hooks/"
cp "$F/brain-backup.sh" "$CLAUDE_DIR/hooks/brain-backup.sh"
chmod +x "$CLAUDE_DIR/hooks/"*.sh
cp "$F/skills/alive-presave/SKILL.md" "$CLAUDE_DIR/skills/alive-presave/SKILL.md"
ok "alive-context-guard hook, status line, alive-presave skill"

S="$CLAUDE_DIR/settings.json"
[ -f "$S" ] || echo '{}' > "$S"
cp "$S" "$S.bak-context-pack-$(date +%Y%m%d%H%M%S)"
G="bash ~/.claude/hooks/alive-context-guard.sh"
jq --arg g "$G" --arg b "bash ~/.claude/hooks/brain-backup.sh" '
  def addhook(ev; m; cmd; extra):
    .hooks[ev] = ((.hooks[ev] // []) as $h
      | if ([$h[]?.hooks[]?.command] | index(cmd)) then $h
        else $h + [({hooks: [({type:"command", command:cmd} + extra)]} + (if m == "" then {} else {matcher:m} end))] end);
  .hooks = (.hooks // {})
  | addhook("UserPromptSubmit"; ""; $g + " watch"; {timeout:5})
  | addhook("PostToolUse"; ""; $g + " watch"; {timeout:5})
  | addhook("PreCompact"; ""; $g + " precompact"; {timeout:30, statusMessage:"Saving session snapshot to ALIVE…"})
  | addhook("SessionStart"; "compact"; $g + " postcompact"; {timeout:10})
  | addhook("SessionEnd"; ""; $b; {timeout:30})
  | if .statusLine then . else .statusLine = {type:"command", command:"bash ~/.claude/hooks/statusline.sh"} end
' "$S" > "$S.tmp" && mv "$S.tmp" "$S" && ok "settings.json updated (backup saved next to it)"
jq -e '.statusLine.command | test("statusline.sh")' "$S" >/dev/null || \
  warn "You already had a status line, so it was left alone. The 50%/70% save reminders need ~/.claude/hooks/statusline.sh as the status line."

MD="$CLAUDE_DIR/CLAUDE.md"
if grep -q 'context-pack:start' "$MD" 2>/dev/null; then ok "CLAUDE.md already has the pack rules"
else
  python3 - "$F/CLAUDE.md.template" "$MD" "$NAME" "$BRAIN" "$ALIVE" <<'PY'
import sys, os
tpl, out, name, brain, alive = sys.argv[1:]
home = os.path.expanduser("~")
t = open(tpl).read().replace("__NAME__", name).replace("__BRAIN__", brain.replace(home, "~")).replace("__ALIVE__", alive.replace(home, "~") + "/")
prev = open(out).read() + "\n\n" if os.path.exists(out) else ""
open(out, "w").write(prev + t)
PY
  ok "Rules added to ~/.claude/CLAUDE.md"
fi

# Warp: hide the agent toolbar that sits on top of Claude Code
W="$HOME/.warp/settings.toml"
mkdir -p "$HOME/.warp"
if ! grep -q 'should_render_cli_agent_toolbar' "$W" 2>/dev/null; then
  if grep -q '^\[agents.third_party\]' "$W" 2>/dev/null; then
    warn "Warp: set Settings → AI → third-party CLI agent toolbar to off yourself"
  else printf '\n[agents.third_party]\nshould_render_cli_agent_toolbar = false\n' >> "$W"; ok "Warp toolbar off"; fi
fi

# ── 6. GitHub backup of the brain (optional) ──────────────────────────────
say "6/6 GitHub backup"
if [ -d "$BRAIN/.git" ]; then ok "Brain is already a git repo"
elif [ -z "$TEST" ] && confirm "Back up your brain to a private GitHub repo? (free account needed)" y; then
  gh auth status >/dev/null 2>&1 || gh auth login --web --git-protocol https < $TTY
  if gh auth status >/dev/null 2>&1; then
    cp "$F/brain-gitignore" "$BRAIN/.gitignore"
    RN="$(ask "Repo name" "$(echo "${NAME}-brain" | tr '[:upper:] ' '[:lower:]-')")"
    ( cd "$BRAIN" && git init -q -b main && git add -A && git commit -q -m "Brain: first commit" \
      && gh repo create "$RN" --private --source . --push >/dev/null ) \
      && ok "Private repo github.com/$(gh api user -q .login)/$RN, backed up after every Claude session" \
      || warn "GitHub backup didn't finish. Re-run the installer to try again."
  else warn "Skipped: not signed in to GitHub"; fi
else ok "Skipped"; fi

cat <<EOF

  ✅ Done.

  Next:
   1. Open Warp, type:  claude   (sign in the first time)
   2. Say:  "Read ~/.claude/CLAUDE.md and help me set up my world"
      then try  /alive:create-walnut  for your first project.
   3. Open $BRAIN in Obsidian to see your notes.

  Read the why: https://github.com/$REPO#readme
EOF
