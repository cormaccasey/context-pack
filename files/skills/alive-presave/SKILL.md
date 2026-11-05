---
name: alive-presave
description: Save this session's full working context into ALIVE as a checkpoint note, without asking questions. HARD RULE - run this immediately whenever a hook says context is near compaction or a pre-compaction save was missed, and whenever the user says "presave", "save context to alive" or "checkpoint before compaction".
user-invocable: true
---

# ALIVE pre-compaction save

Context is about to be compressed. Anything not written down now gets reduced to a summary. Your job:
write one complete, self-contained checkpoint note into ALIVE **fast and without asking questions**.
Do not use AskUserQuestion here. Do not run `/alive:save`. It's interactive and too slow for this.

## 1. Gather (from the conversation, or from the raw snapshot)

If a hook pointed you at a raw snapshot (`ALIVE/03_Inbox/Session snapshot ….md`), compaction has
already happened, so read that file and build the note from it. Otherwise use the live conversation.

Capture everything a fresh Claude would need to carry on with no other context:

- **Goal**: what the user is trying to achieve this session, in his words where possible
- **Walnut**: which ALIVE walnut/project this belongs to (check the ALIVE session line or
  `.alive/_squirrels/<session>.yaml` `walnut:` field; otherwise infer from the work)
- **Decisions made** and the reasoning behind each
- **What's done**: concrete outcomes, with exact file paths, URLs, IDs, commands
- **In progress / open**: where the work stopped, what's half-finished, known bugs
- **Next steps**: the ordered list of what to do next
- **Key facts & gotchas**: things learned the hard way, constraints, preferences the user stated
- **Files touched**: paths created or edited
- **People / external**: anyone mentioned, emails/messages drafted or sent

Be specific. Paths, numbers, names and exact wording beat summaries. Long is fine. Lost is not.

## 2. Write the note

Path: `<your ALIVE folder>/03_Inbox/ (the path is in ~/.config/alive/world-root)<Topic> checkpoint YYYY-MM-DD HHMM.md`.
Use a plain-English topic (e.g. `Website checkout checkpoint 2026-10-14 1530.md`).
Use the inbox even when the walnut is known. The walnut goes in frontmatter so it can be routed later.

```markdown
---
type: session-checkpoint
session: <session id>
walnut: <walnut name or null>
created: YYYY-MM-DD HH:MM
snapshot: "[[Session snapshot … ]]"   # if a raw snapshot exists
---

# <Topic>: session checkpoint

## Goal
## Decisions
## Done
## In progress
## Next steps
## Key facts & gotchas
## Files touched
## People & external
```

If a walnut is known, add `Related: [[<walnut>]]` under the title.

## 3. Mark it saved

```bash
bash ~/.claude/hooks/alive-context-guard.sh mark-saved <session id> "<note path>"
```

This stops the reminders and tells the post-compaction hook where the checkpoint is.

## 4. Carry on

Tell the user in one line: `Context checkpoint saved to ALIVE → <note name>`. Then go straight back to
the task you were doing. Routing the note into its walnut can wait for `/alive:capture-context`
or `/alive:save` later.
