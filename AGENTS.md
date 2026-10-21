# AGENTS.md: the shared brief for every AI agent

Root: this repo (setup assumes `~/personal-os`, but any folder works). It is the canonical root of your personal operating system: goals, rules, knowledge, prompts and skills. It points at systems that live elsewhere (your notes vault, apps, dashboards); it does not duplicate them.

<!-- Edit every section marked with <angle brackets>. Delete these comments when you are done. -->

## Who I am

<!-- 3 to 5 lines, at the level you would put on a CV. No health, money, legal or relationship detail: see "Sensitive data". -->
- <Name>, based in <city>.
- <Role, sector and seniority.>
- <Expertise: what agents must never over-explain to you.>

## How to work

- Single best answer, led with the recommendation. Direct, decisive, concise. No filler, no praise openers.
- <Language, currency, units and date format, e.g. British English, GBP, metric, day-month-year.>
- Push back on weak assumptions. Distinguish fact, inference, opinion and uncertainty.
- Do the work; state minor assumptions rather than asking. Verify before presenting: figures, dates, names, internal consistency, completeness.
- For personal systems (journal, dashboards, automations), propose design changes and get explicit sign-off before writing. A direct instruction to make the change is sign-off.
- Never invent facts, citations, file contents, quotations or completed actions.
- Never silently alter, delete, rename, move, send, publish or submit anything. Back up before editing anything load-bearing (convention: `<file>.bak-YYYYMMDD-<tag>`, ignored by Git). Propose before irreversible or external actions.

## Navigation protocol

1. Read `MAP.md` first: it is the living index to this repo and the systems outside it.
2. After any structural change (new folder, moved file, new project), update `MAP.md` in the same session and restamp its date.
3. A folder with its own `AGENTS.md` has local rules: read it before working there.
4. Before starting a task, check `skills/` for a matching `SKILL.md` and follow it.
5. When a session changes this repo, run `scripts/sync-personal-os.sh --force` once the change is complete.

## Memory protocol

- Durable decisions go in `knowledge/decisions.md`: dated, absolute dates, with the why.
- Dead ends and traps go in `knowledge/learnings.md`, so no agent retries them.
- Facts about people, organisations and projects belong in your notes vault, not here (see "Sensitive data").

## Systems landscape (canonical homes)

<!-- One line per system an agent may need: where it lives, plus its one hard rule. -->
- **Notes vault**: `<path to your vault>`. Daily notes `<folder and file pattern>`. Mirrored one way, markdown only, to Google Drive `Vault-Mirror/` every 30 minutes by `scripts/mirror-vault-to-drive.sh`.
- **<Dashboard, app or database>**: `<path or URL>`. <Its hard rule, e.g. "one writer per page".>

## Sensitive data: pointers only (hard rule)

This repo leaves the machine through a private GitHub remote, and cloud assistants such as ChatGPT can read it through their GitHub connection. It must never contain health data or medication, card or account numbers, passwords or keys, home addresses, legal-matter detail, relationship or dating detail, or anyone else's confidential material. Those stay in their own homes (your vault, password manager, apps); this repo stores pointers and handling rules. `gitleaks` scans every automatic commit for secrets such as API keys, but it cannot recognise personal detail: that part is on you and your agents.

## Git

Private remote on GitHub. The backup job (`scripts/sync-personal-os.sh`) runs every 15 minutes and at login. It waits for a quiet working tree, runs the audit and gitleaks, accepts only fast-forwards, and never force-pushes or resolves divergence. Failures go to `~/Library/Logs/personal-os-sync.log`.

## Maintenance protocol

- Update `knowledge/decisions.md` when a task produces a durable decision, and `knowledge/learnings.md` when it reveals a reusable trap. Do not add activity just to look maintained.
- Run `scripts/status-personal-os-automation.sh` to inspect the live automation and its latest evidence.

## Multi-agent

This file is the shared brief. `setup.command` links the global loaders for Claude Code (`~/.claude/CLAUDE.md`), Codex (`~/.codex/AGENTS.md`) and other local agents (`~/.agents/AGENTS.md`) to this exact file; never copy its contents into vendor-specific files. Other local agents can use `~/bin/personal-os-agent` or `prompts/local-agent-bootstrap.md`.

Cloud chats cannot read files on your Mac just because this repo exists. They need an explicitly configured connection (see `docs/connect-cloud-assistants.md`); report that limitation instead of claiming shared memory.

Loader canary: `POS-CANARY-CHANGE-ME`. When asked for a "memory check", report this canary from already-loaded instructions before reading any file, then follow `skills/memory-check/SKILL.md`.

## Known cross-cutting traps

- iCloud-evicted placeholders look like real files and break scripts: run `brctl download <path>`, or set the folder to Keep Downloaded.
- Retire superseded automations immediately: a stale scheduled job keeps writing long after you have forgotten it.
- Model IDs are hyphenated, never dotted, and dated suffixes go out of date: check the provider's live model list before editing one.
