# GitHub, in plain English

## What GitHub is

**GitHub is Google Drive for code and text files, with a full history of every change.**

It's built on a tool called **git**, which takes a "snapshot" (a *commit*) of a folder whenever you
save your progress. GitHub stores those snapshots online in a **repository** ("repo"), which is just
one project folder plus its full history.

What that gives you:

| Feature | What it means for you |
|---|---|
| **Backup** | The folder lives on GitHub as well as your laptop. Laptop dies, nothing lost. |
| **History / undo** | Every version of every file is kept. "What did this note say last Tuesday?" can always be answered. |
| **Sync** | The same repo on two computers (or a teammate's) stays in step. |
| **Sharing** | A repo can be **private** (only people you invite) or **public** (anyone can see and download it). |
| **Hosting and deploys** | Websites can be published straight from a repo (e.g. Cloudflare Pages, Vercel, GitHub Pages). |
| **Collaboration** | Several people can change the same project without overwriting each other. |

It's free for private and public repos.

## How this setup uses it

1. **Code projects.** Every app, website or tool Claude builds for you gets its own private repo.
   That's your backup and undo button, and how sites get deployed.
2. **Your brain backup** (optional in the installer). Your notes folder is a private repo. After every
   Claude Code session it quietly commits and pushes, so you get an off-site copy and history of every
   note, and you can restore anything.
3. **Distribution.** This pack itself lives on GitHub. The one-line installer downloads it from there,
   and so does the ALIVE plugin. When the pack is improved, re-running the installer picks up the
   changes.

Claude drives all of this through the **GitHub CLI** (`gh`). You never need to learn git commands.
Just say "commit this", "make a private repo for this project" or "what changed since yesterday?".

## What a GitHub organisation ("org") is

By default, repos belong to your **personal account** (`github.com/your-name/project`).

An **organisation** is a shared account for a company or team (`github.com/your-company/project`):

- Repos belong to the *company*, not one person, so nothing is stuck if someone leaves.
- You can **invite people by email** (personal accounts can only add collaborators by username).
- People join as members, are grouped into **teams**, and get access per repo (read, write, admin).
- Billing, security settings and audit logs sit in one place.
- Free to create. Paid plans add extras like more Actions minutes and advanced permissions.

**When you need one:** once more than one person works on the same repos, or the work belongs to a
business rather than a person. A solo person backing up their brain doesn't need one.
