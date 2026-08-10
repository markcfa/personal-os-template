# personal-os — a template

One folder that gives every AI agent you use long-term memory, house rules, and a map of your life.

AI agents are goldfish: every new chat starts from zero and you re-explain yourself. This template fixes that. It's a small git repo — a "personal operating system" — that any AGENTS.md-aware agent (Claude Code, Codex/ChatGPT, Kimi CLI, Cursor, …) reads on open and starts fully loaded: who you are, how you like to work, what it must never touch, where everything lives, and what's already been decided or tried. Because every agent writes decisions back to the same log, they share one memory instead of each app hoarding its own.

## Structure

```
AGENTS.md                  # the shared brief — identity, working rules, hard rules
CLAUDE.md                  # Claude Code loader (@AGENTS.md)
MAP.md                     # living index — agents read it first, update it on change
connect-github.command     # macOS double-click: private GitHub backup/sync
goals/north-star.md        # your 90-day goals + long game
knowledge/decisions.md     # dated decisions log, incl. "do not relitigate" list
knowledge/learnings.md     # dead ends and traps — so no agent retries them
work/ people/ health/      # example domain rule files: rules live here, data doesn't
prompts/  projects/  inbox/
skills/personal-os-setup/  # the meta-skill: an agent interviews you and fills all this in
skills/weekly-review/      # example ritual skill — customise to your week
```

## Quickstart

1. Click **Use this template** (or fork/clone) and put the folder somewhere sensible on your machine.
2. Open it with any coding/desktop agent.
3. Say: **"Read skills/personal-os-setup/SKILL.md and set up my personal OS."** The agent interviews you and fills in every template.
4. Double-click `connect-github.command` (macOS) to back it up to a **private** GitHub repo.

## The two rules that make it work

**Pointers, not payloads.** The repo may leave your machine (git remote, cloud sync), so it never contains sensitive data — health values, finances, relationship detail, client material. It records *where* those live and *how* to handle them.

**Agents maintain the map.** MAP.md is read first every session and updated whenever the structure changes. Decisions get dates and a why; dead ends get written down. That's the whole memory system — no vendor lock-in, works with whatever model wins next year.

## Licence

MIT — take it, strip it, rebuild it. Built by [Mark Tully](https://github.com/markcfa).
