#!/bin/bash
# ALIVE context guard — makes sure session context lands in ALIVE before compaction.
#
# Modes (first arg):
#   watch        UserPromptSubmit / PostToolUse. Each time context use crosses a
#                checkpoint level (50% and 70%), tells Claude to run alive-presave
#                immediately. The first save creates the checkpoint note; the
#                next level updates that same note.
#   precompact   PreCompact. Always dumps the conversation since the last
#                compaction to ALIVE/03_Inbox as a raw snapshot (the safety net).
#   postcompact  SessionStart(compact). If no checkpoint was saved before
#                compaction, tells Claude to run alive-presave from the snapshot.
#   mark-saved   Called by the alive-presave skill: `mark-saved [session_id] [note_path]`.
#
# Context % comes from the status line, which writes ~/.claude/state/ctx/<sid>.pct.
# Levels: ALIVE_PRESAVE_LEVELS (default "50 70").

MODE="${1:-watch}"
STATE_DIR="$HOME/.claude/state/ctx"
ALIVE_DIR="$(head -1 "$HOME/.config/alive/world-root" 2>/dev/null)"
[ -z "$ALIVE_DIR" ] && ALIVE_DIR="$HOME/Documents/Brain/ALIVE"
INBOX="$ALIVE_DIR/03_Inbox"
LEVELS="${ALIVE_PRESAVE_LEVELS:-50 70}"
mkdir -p "$STATE_DIR"

if [ "$MODE" = "mark-saved" ]; then
  SID="${2:-}"
  if [ -z "$SID" ]; then
    # Fall back to the most recently active transcript
    SID=$(basename "$(ls -t "$HOME"/.claude/projects/*/*.jsonl 2>/dev/null | head -1)" .jsonl)
  fi
  [ -z "$SID" ] && { echo "no session id found" >&2; exit 1; }
  printf '%s\n%s\n' "$(date '+%Y-%m-%d %H:%M')" "${3:-}" > "$STATE_DIR/$SID.saved"
  echo "checkpoint marked for session $SID"
  exit 0
fi

INPUT=$(cat)
SID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty')
TRANSCRIPT=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty')
EVENT=$(printf '%s' "$INPUT" | jq -r '.hook_event_name // empty')
[ -z "$SID" ] && exit 0
SAFE_SID="${SID//[^A-Za-z0-9._-]/_}"

emit() { # $1 = event name, $2 = text for Claude
  jq -n --arg e "$1" --arg t "$2" '{hookSpecificOutput:{hookEventName:$e, additionalContext:$t}}'
}

case "$MODE" in
watch)
  PCT=$(head -1 "$STATE_DIR/$SAFE_SID.pct" 2>/dev/null)
  case "$PCT" in ''|*[!0-9]*) exit 0 ;; esac
  LEVEL=0
  for L in $LEVELS; do [ "$PCT" -ge "$L" ] && [ "$L" -gt "$LEVEL" ] && LEVEL=$L; done
  [ "$LEVEL" -eq 0 ] && exit 0
  LAST=$(head -1 "$STATE_DIR/$SAFE_SID.warned" 2>/dev/null)
  case "$LAST" in ''|*[!0-9]*) LAST=0 ;; esac
  [ "$LEVEL" -le "$LAST" ] && exit 0
  echo "$LEVEL" > "$STATE_DIR/$SAFE_SID.warned"
  NOTE=$(sed -n 2p "$STATE_DIR/$SAFE_SID.saved" 2>/dev/null)
  if [ -n "$NOTE" ] && [ -f "$NOTE" ]; then
    WHAT="UPDATE the existing checkpoint note in place at \"$NOTE\" (rewrite every section so it reflects the whole session so far; do not create a new file)"
  else
    WHAT="create this session's checkpoint note"
  fi
  emit "${EVENT:-UserPromptSubmit}" "HARD RULE — ALIVE PRE-COMPACTION SAVE (${LEVEL}% checkpoint): context is at ${PCT}%. Before doing anything else (including answering the current message or continuing the current task), invoke the \`alive-presave\` skill and ${WHAT}. Session id: ${SID}. When written, run: bash ~/.claude/hooks/alive-context-guard.sh mark-saved ${SID} \"<note path>\". Then carry on with the task."
  ;;

precompact)
  [ -f "$TRANSCRIPT" ] || exit 0
  mkdir -p "$INBOX"
  STAMP=$(date '+%Y-%m-%d %H%M')
  OUT="$INBOX/Session snapshot ${STAMP} ${SAFE_SID:0:8}.md"
  python3 - "$TRANSCRIPT" "$OUT" "$SID" "$(printf '%s' "$INPUT" | jq -r '.trigger // "auto"')" <<'PY'
import json, sys
src, out, sid, trigger = sys.argv[1:5]
lines = []
with open(src, encoding="utf-8", errors="replace") as f:
    for raw in f:
        try:
            lines.append(json.loads(raw))
        except Exception:
            pass
# Only what happened since the last compaction — earlier parts were already snapshotted.
start = 0
for i, e in enumerate(lines):
    if e.get("type") == "system" and e.get("subtype") == "compact_boundary":
        start = i + 1
cwd = next((e.get("cwd") for e in lines if e.get("cwd")), "")

def clip(s, n):
    s = s.strip()
    return s if len(s) <= n else s[:n] + f" … [+{len(s)-n} chars]"

body = []
for e in lines[start:]:
    t = e.get("type")
    if t not in ("user", "assistant") or e.get("isMeta"):
        continue
    content = (e.get("message") or {}).get("content")
    if isinstance(content, str):
        content = [{"type": "text", "text": content}]
    for b in content or []:
        bt = b.get("type")
        if bt == "text" and b.get("text", "").strip():
            who = "**You:**" if t == "user" else "**Claude:**"
            body.append(f"{who} {clip(b['text'], 6000)}\n")
        elif bt == "tool_use":
            body.append(f"> 🔧 `{b.get('name')}` {clip(json.dumps(b.get('input', {}), ensure_ascii=False), 400)}\n")
        elif bt == "tool_result":
            c = b.get("content")
            if isinstance(c, list):
                c = " ".join(x.get("text", "") for x in c if isinstance(x, dict))
            if c:
                body.append(f"> ↳ {clip(str(c), 300)}\n")

with open(out, "w", encoding="utf-8") as f:
    f.write(f"""---
type: session-snapshot
session: {sid}
trigger: {trigger}
cwd: {cwd}
created: {__import__('datetime').datetime.now().strftime('%Y-%m-%d %H:%M')}
---

# Session snapshot (raw, pre-compaction)

Automatic dump taken just before Claude Code compacted the conversation. Raw material only — the
curated checkpoint is written by the `alive-presave` skill. Route with `/alive:capture-context`.

""")
    f.write("\n".join(body))
PY
  printf '%s\n' "$OUT" > "$STATE_DIR/$SAFE_SID.snapshot"
  jq -n --arg p "$OUT" '{systemMessage: ("ALIVE: raw session snapshot saved to " + $p)}'
  ;;

postcompact)
  SNAP=$(head -1 "$STATE_DIR/$SAFE_SID.snapshot" 2>/dev/null)
  if [ -f "$STATE_DIR/$SAFE_SID.saved" ]; then
    NOTE=$(sed -n 2p "$STATE_DIR/$SAFE_SID.saved")
    MSG="ALIVE: a pre-compaction checkpoint was saved for this session${NOTE:+ at: $NOTE}. Read it if you need detail lost in the summary. Raw snapshot: ${SNAP:-none}."
  else
    MSG="HARD RULE — ALIVE PRE-COMPACTION SAVE MISSED: the conversation was just compacted before a checkpoint was saved. Before doing anything else, invoke the \`alive-presave\` skill, using the raw snapshot at \"${SNAP:-<none found>}\" as the source (it holds the full pre-compaction conversation). Session id: ${SID}. When done, run: bash ~/.claude/hooks/alive-context-guard.sh mark-saved ${SID} \"<note path>\". Then continue the task."
  fi
  # New context window: levels start again. The note path is kept (in .saved)
  # so later checkpoints keep updating the same note.
  rm -f "$STATE_DIR/$SAFE_SID.warned" "$STATE_DIR/$SAFE_SID.pct"
  emit "SessionStart" "$MSG"
  ;;
esac
exit 0
