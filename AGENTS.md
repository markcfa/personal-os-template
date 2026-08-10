# AGENTS.md — <your name>'s Personal OS

Root: `<path to this folder on your machine>`. This repo is the canonical root of your personal operating system — goals, plans, knowledge, prompts, skills, and the rules agents follow. It points at systems that live elsewhere; it does not duplicate them.

> Placeholders are in `<angle brackets>`. Run `skills/personal-os-setup` to have an agent interview you and fill them in.

## Who I am

<Name, where you're based, what you do, how technical you are — two or three sentences. Tell agents what NOT to over-explain to you.>

## How to work with me

- <Answer style: single best answer or options? Direct or gentle? Lead with the recommendation?>
- <Locale: language variant, currency, units, date format.>
- <How much to ask vs assume — e.g. "state minor assumptions rather than asking".>
- Never invent facts, citations, file contents, or completed actions.
- Never silently alter, delete, rename, move, send, publish, or submit anything. Back up before editing anything load-bearing. Propose before irreversible or external actions.

## Navigation protocol

1. Read `MAP.md` first — the living index to this repo and the systems outside it.
2. After any structural change, update `MAP.md` in the same session and restamp its date.
3. Folders with their own `AGENTS.md` have local rules — read before working there.
4. Before starting a task, check `skills/` for a matching `SKILL.md` and follow it.

## Memory protocol

- Durable decisions → `knowledge/decisions.md` — dated, absolute dates, with the why.
- Dead ends and traps → `knowledge/learnings.md` — so no agent retries them.
- Decisions marked "do not relitigate" are settled — don't reopen them uninvited.

## Systems landscape

<One line per external system — notes app, task manager, calendar, dashboards, databases: where it lives and what it owns. Name a single writer for anything two systems could touch.>

## Sensitive data — pointers only (hard rule)

This repo may leave the machine (git remote, cloud sync). It must never contain: health values, financial account details, relationship detail, legal specifics, client-confidential material, or anyone else's personal data. Those stay in their current homes; this repo stores pointers and handling rules.

## Git

Private remote (`connect-github.command`). Commit at the end of any session that changes the repo, imperative message. Nothing covered by the Sensitive rule is ever committed.

## Multi-agent

This file is the shared brief across all agents (Claude, Codex/ChatGPT, Kimi, …). Claude Code loads it via `CLAUDE.md`. `knowledge/` is the shared memory layer — whichever vendor you are, write decisions there.
