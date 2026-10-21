---
name: personal-os-setup
description: Set up a person's personal OS from this template. Use when the user says "set up my personal OS", "fill in this template", or has just cloned personal-os and wants it personalised. Interviews the user, fills every placeholder, and wires up private git.
---

# Personal OS setup

You are turning this template into *their* operating system. Interview first, write second. Never invent an answer to skip a question: blanks are better than fabrications.

## 1. Interview (batch the questions; respect their time)

- **Placement**: where does this folder live on their machine? Note whether that path cloud-syncs (Documents/Desktop often do); it matters for question 3.
- **Existing systems**: what do they already use for notes, tasks, calendar, tracking? For each: does it stay canonical (this repo points to it) or will it migrate in over time? Warn that moving anything with schedulers or hardcoded paths is a project, not a file move.
- **Sensitive data policy**: recommend pointers-only (sensitive detail stays in current homes; repo stores pointers + rules), especially if they want a git remote or the path cloud-syncs.
- **Versioning**: git + private remote (recommended), git local-only, or none.
- **Working style**: answer style (single best answer vs options), directness, locale (language variant, currency, units, date format), how much to ask vs assume.
- **Goals**: their 90-day outcomes (max ~6) and, if they're up for it, the long-game eras. Offer to draft placeholders they'll rewrite, clearly marked as drafts.

## 2. Write

- Fill every `<placeholder>` in `AGENTS.md`, `MAP.md`, `goals/north-star.md`, `prompts/cloud-llm-context.md` and `prompts/cloud-llm-context-short.md` from their answers. Delete example domain folders they don't want; add ones they do (rules, never payloads).
- Build the MAP.md external-systems table from their real systems, including a single-writer note for anything two systems could touch.
- Seed `knowledge/decisions.md` with today's setup decisions: dated, with the why.
- Anything you drafted rather than they stated: mark it as a draft for them to rewrite.

## 3. Wire up

- If `config.sh` does not exist yet, ask them to run `setup.command` in Terminal (it asks for their name, email, vault and Google Drive account, links the agent loaders and installs the background jobs). It is interactive, so they run it, not you.
- If they have no GitHub remote yet: `gh repo create <folder-name> --private --source=. --push`, then re-run `setup.command` so the backup jobs install.
- Final check: nothing sensitive in the repo, every placeholder either filled or deliberately blank, MAP.md date stamped, and `scripts/status-personal-os-automation.sh` shows no FAIL.

## 4. Tell them how it works

One short paragraph: agents read MAP.md first, decisions go in the log, dead ends in learnings, skills get written the third time a process repeats, and the repo is the shared memory across every agent they use.
