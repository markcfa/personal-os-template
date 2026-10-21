# Personal OS

One folder that gives every AI you use long-term memory, house rules and a map of your life.

AI agents are goldfish: every new chat starts from zero and you re-explain yourself. This template fixes that. It is a small Git repo, a "personal operating system", that every agent reads: Claude Code and Codex load it automatically on your Mac, ChatGPT reads it through GitHub, ChatGPT and Gemini read your notes through a Google Drive mirror, and Venice and Meta AI get a short profile. Because every agent writes decisions back to the same log, they share one memory instead of each app hoarding its own. It backs itself up to a private GitHub repo every 15 minutes, and an optional daily task tells Claude what you did in the other assistants.

## What you get

- **One shared brief.** `AGENTS.md` says who you are, how you want agents to work and your hard rules. Every local agent loads the same file, so you never maintain five copies.
- **A map and a memory.** `MAP.md` says where everything lives; `knowledge/decisions.md` and `knowledge/learnings.md` stop agents relitigating decisions or repeating mistakes.
- **Safe automatic backup.** Every 15 minutes the repo is committed and pushed to your private GitHub repo, after a `gitleaks` secret scan. It never force-pushes or merges anything by itself: when in doubt it stops and logs why.
- **Your notes for cloud assistants.** An optional one-way, markdown-only copy of your Obsidian vault into Google Drive every 30 minutes, so ChatGPT and Gemini can search it. Folders you name (for example `Private.nosync`) never leave your Mac.
- **A context pack.** A profile you paste into ChatGPT, Gemini, Venice and Meta AI so they answer the way you want.
- **A digest back to Claude (optional).** A daily Claude task reads your other assistants' chats, read-only, and files a summary in Drive.

## How it fits together

```
   Claude Code / Codex ── load AGENTS.md at startup ──┐
                                                      │
   ~/personal-os (this repo) ── every 15 min ──> private GitHub repo ──> ChatGPT (GitHub app)
                                                      
   Obsidian vault ── every 30 min, .md only ──> Google Drive/Vault-Mirror ──> ChatGPT, Gemini
                                                      
   Venice, Meta AI <── paste prompts/cloud-llm-context*.md

   ChatGPT, Gemini, Meta AI, Venice ── daily, read-only ──> Drive/AI-Digests ──> Claude
```

## What you need

- A Mac with Git (`xcode-select --install` if `git` is missing) and [Homebrew](https://brew.sh).
- `gitleaks` and the GitHub CLI: `brew install gitleaks gh`
- A GitHub account.
- Optional: an Obsidian (or any Markdown) vault and [Google Drive for desktop](https://www.google.com/drive/download/) for the mirror; Claude with Claude in Chrome for the digest; Claude Code or Codex for local agents.

## Set up (about 15 minutes)

1. On this page, click **Use this template** › **Create a new repository**. Name it `personal-os` and choose **Private**. It will hold your personal notes.
2. In Terminal, sign the GitHub CLI in (this also lets the background jobs push) and clone your new repo:
   ```sh
   gh auth login
   gh repo clone <your-github-name>/personal-os ~/personal-os
   ```
3. Run setup and answer its questions. It is safe to re-run.
   ```sh
   ~/personal-os/setup.command
   ```
   It asks for your name, the email on your GitHub account, your vault folder and your Google Drive account (both optional), and whether to point Claude Code and Codex at `AGENTS.md`. Existing loader files are backed up first, never overwritten. If macOS asks whether `sh` may access your Documents or Google Drive, allow it.
4. Make it yours: fill in `AGENTS.md` (Who I am, How to work, Systems), `MAP.md`, `goals/north-star.md` and the two `prompts/cloud-llm-context*.md` files. Anything marked `<like this>` is a placeholder.
   Easier: open the folder with Claude Code or Codex and say **"Read skills/personal-os-setup/SKILL.md and set up my personal OS."** The agent interviews you and fills everything in.
5. Connect your cloud assistants: [docs/connect-cloud-assistants.md](docs/connect-cloud-assistants.md).
6. Optional: set up the daily digest from [prompts/other-ai-digest.md](prompts/other-ai-digest.md).

Check that everything is running at any time:

```sh
~/personal-os/scripts/status-personal-os-automation.sh
```

## Day to day

- Work as normal. Agents read `AGENTS.md` and `MAP.md`, file decisions and learnings, and the backup job pushes their changes.
- To run Claude Code or Codex with a sync just before and after the session: `~/bin/personal-os-agent claude`.
- If the sync log (`~/Library/Logs/personal-os-sync.log`) says DEFER all day, run `~/personal-os/scripts/unstick-personal-os-sync.sh`.
- [AUTOMATION.md](AUTOMATION.md) lists every background job, every log line and how to recover.

## The two rules that make it work

**Pointers, not payloads.** The repo leaves your machine (GitHub, and the assistants that read it), so it never contains sensitive data: health values, finances, relationship detail, client material. It records *where* those live and *how* to handle them.

**Agents maintain the map.** `MAP.md` is read first every session and updated whenever the structure changes. Decisions get dates and a why; dead ends get written down. That is the whole memory system: no vendor lock-in, and it works with whatever model wins next year.

## Keep it safe

- **Keep your copy private.** Setup stops if it finds your remote is public.
- **Pointers, not data.** Never put health details, account numbers, passwords, home addresses, legal matters or relationship detail in this repo; ChatGPT can read it. `gitleaks` catches secrets such as API keys, not personal detail.
- **The mirror is one way.** It copies your vault to Drive and deletes there what you delete in the vault. Don't edit files inside `Vault-Mirror/`: the next run overwrites them. It refuses to run if Drive is missing or your vault looks empty, so a glitch cannot wipe the copy.
- **Connecting Google Drive or Gmail to an assistant shares the whole account**, not one folder. Decide what you are comfortable with first.
- **To remove it:** `~/personal-os/scripts/uninstall.sh` stops and deletes the background jobs and the launcher. It leaves your files alone.

## Licence

MIT: take it, strip it, rebuild it. See [LICENSE](LICENSE). Built by [Mark Tully](https://github.com/markcfa).
