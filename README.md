# Context Pack

**Context, context, context.** A ready-made setup for working with Claude Code so it remembers your
work, your rules and your projects, across every session, without you repeating yourself.

## Install (Mac, about 10 minutes)

Open the **Terminal** app and paste:

```bash
curl -fsSL https://raw.githubusercontent.com/cormaccasey/context-pack/main/install.sh | bash
```

You'll be asked your first name, where to keep your brain, your Mac password (once), and to sign in
to Claude and, if you want the backup, GitHub. Re-running it is safe. It skips anything already done
and never touches your notes.

---

## The thesis

Claude is only as good as what it can see. It starts every session knowing nothing about you. Then,
as a long session fills up, it compresses ("compacts") the conversation, and the details get lost.
Most people deal with this by re-explaining themselves every day.

The fix is to **store context on purpose, in layers, as plain files you own**:

| Layer | What it holds | Where it lives | Who writes it |
|---|---|---|---|
| **1. Rules** | How you work, hard rules, where things go | `~/.claude/CLAUDE.md` (every session) and a `CLAUDE.md` in each project folder | You, plus Claude when you correct it twice |
| **2. Memory** | Small facts Claude learns about you and your work, each with the *why* | `~/.claude/projects/…/memory/` | Claude, automatically |
| **3. The brain (ALIVE)** | Everything worth keeping: projects, people, plans, decisions, research, meeting notes | An Obsidian vault on your Mac, organised as *walnuts* | Claude and you, via `/alive:` commands |
| **4. Safety net** | A checkpoint of the session before it gets compressed | `ALIVE/03_Inbox/` | Hooks, automatically |

Three principles:

1. **If it's not written down, it didn't happen.** Decisions, preferences and "never do that again"
   moments go into a file the same day.
2. **One home for everything.** Notes don't live in Downloads, chat history or random docs. They live
   in the brain, so Claude can always find them (`/alive:search-world`).
3. **Save before you forget.** Context fills up. The pack watches it and saves a checkpoint to the
   brain at 50% and 70% full, plus a raw snapshot right before compaction. Nothing is lost.

## What the installer sets up

| Piece | What it is | Why |
|---|---|---|
| **Warp** | A modern terminal app | The nicest place to run Claude Code. Tabs, search, readable output. |
| **Claude Code** | Claude, working directly on your Mac | It can read and write your files, run tools, and build things. |
| **Obsidian + your brain** | A folder of plain markdown notes, viewed in Obsidian | Your second brain. Readable by you *and* Claude. Yours forever, no lock-in. |
| **ALIVE** plugin | The structure for the brain: walnuts, inbox, capture, save, search | Gives every project its own home and a running log Claude reads at the start of work. |
| **Context guard hook** | Watches how full the session is | Saves a checkpoint to the brain at 50% and 70%, and a raw snapshot before compaction. |
| **Status line** | `ctx 42%` at the bottom of Claude Code | You always see how full the context is. |
| **`alive-presave` skill** | Writes a full checkpoint note, no questions asked | What the hook calls. You can also say "presave" anytime. |
| **Starter rules** | A `CLAUDE.md` with the house rules | Tells Claude where notes go and to save before compaction. Add your own rules over time. |
| **GitHub backup** (optional) | Your brain in a private GitHub repo, pushed after every session | Off-site backup and full history. Any note can be rolled back. See [GITHUB.md](GITHUB.md). |

## Your first day

1. Open **Warp**, type `claude`, sign in.
2. Say: *"Read ~/.claude/CLAUDE.md and help me set up my world."*
3. Make a walnut for your main project: `/alive:create-walnut`.
4. Work as normal. When something's worth keeping, say *"save this to the brain"* or run `/alive:save`.
5. At the end of the day: `/alive:world` shows what's active and what's stale.

## Daily commands

| Say or type | What happens |
|---|---|
| `/alive:load-context <project>` | Loads a project's brief, people and current work |
| `/alive:capture-context` | Files an email, transcript or doc into the right walnut |
| `/alive:save` | Checkpoints the session into the walnut's log |
| `/alive:search-world <thing>` | Finds anything you've written down before |
| `/alive:world` | Big-picture view of everything |
| "presave" | Instant checkpoint note (what the hook does automatically) |

## Make it yours

The pack is a starting point. Its real value builds up:

- **Every time you correct Claude twice about the same thing**, add a line to `~/.claude/CLAUDE.md`.
- **Every repeated job** (weekly report, client onboarding, a type of email) can become a *skill*:
  ask Claude to "turn this into a skill".
- **Every new project** gets a walnut in the brain *and* its own GitHub repo for the code.

## Uninstall

Delete `~/.claude/hooks/alive-context-guard.sh`, `statusline.sh` and `brain-backup.sh`, the
`~/.claude/skills/alive-presave` folder, and the block between `context-pack:start` and
`context-pack:end` in `~/.claude/CLAUDE.md`. Restore `~/.claude/settings.json` from the
`settings.json.bak-context-pack-…` file next to it. Your brain folder is yours to keep.
