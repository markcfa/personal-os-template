# MAP.md: where everything lives

**Last updated: <date> · by <who>: <what changed>.**
Agents: read this file first, every session. After any structural change, update it in the same session and restamp the date.

## This repo

```
personal-os/
├── AGENTS.md                  # the shared brief: who you are, how to work, hard rules
├── CLAUDE.md                  # Claude Code loader (@AGENTS.md)
├── MAP.md                     # this file
├── AUTOMATION.md              # what runs in the background, and how to recover
├── setup.command              # first-run setup (safe to re-run)
├── config.sh                  # your settings, written by setup (never committed)
├── goals/north-star.md        # 90-day goals and the long game
├── work/AGENTS.md             # rules for work material
├── people/AGENTS.md           # rules for anything about people (no personal data here)
├── health/AGENTS.md           # rules for health tracking (no values here)
├── knowledge/
│   ├── decisions.md           # dated decisions, newest first, with the why
│   ├── learnings.md           # dead ends and traps, so no agent retries them
│   └── agent-checkins.md      # results of explicit "memory check" tests
├── prompts/
│   ├── README.md
│   ├── local-agent-bootstrap.md   # startup prompt for local agents without native loaders
│   ├── cloud-llm-context.md       # who you are, for cloud assistants (full)
│   ├── cloud-llm-context-short.md # the same in under 1,000 characters
│   └── other-ai-digest.md         # prompt for the optional daily digest task
├── skills/
│   ├── personal-os-setup/     # an agent interviews you and fills in this template
│   ├── memory-check/          # prove an agent loaded AGENTS.md and can write here
│   └── weekly-review/         # example ritual skill: customise or delete
├── docs/connect-cloud-assistants.md # ChatGPT, Gemini, Venice and Meta AI setup
├── scripts/                   # sync, audit, daily check, status, launcher, vault mirror, unstick, install, uninstall
├── launchd/                   # templates for the background jobs
├── projects/README.md         # new projects start here, one AGENTS.md each
└── inbox/README.md            # unfiled drops: file them, then update MAP
```

## Agent loaders

All loaders resolve to `AGENTS.md` in this repo; never maintain their contents separately.

| Agent | Loader |
|---|---|
| Claude Code (global) | `~/.claude/CLAUDE.md` |
| Codex | `~/.codex/AGENTS.md` |
| Any other local agent | `~/.agents/AGENTS.md` |

Launcher: `~/bin/personal-os-agent {claude|codex|COMMAND}` syncs before and after a session.

## Outside this repo (canonical homes: point, don't duplicate)

| System | Where | What |
|---|---|---|
| Notes vault | `<path>` | <what lives there: daily notes, people, projects> |
| Vault mirror | Google Drive `My Drive/Vault-Mirror/` | one-way, markdown-only copy for cloud assistants; `scripts/mirror-vault-to-drive.sh` every 30 minutes; folders in `POS_MIRROR_EXCLUDE` (config.sh) never copied |
| Cloud assistants | ChatGPT · Gemini · Venice · Meta AI | profile from `prompts/cloud-llm-context*.md`; connections in `docs/connect-cloud-assistants.md` |
| AI digest (optional) | Google Drive `AI-Digests/` | daily Claude scheduled task from `prompts/other-ai-digest.md`: what you did in the other assistants |
| <Other system> | <where> | <what> |
