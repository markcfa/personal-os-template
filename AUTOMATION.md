# Personal OS automation

## What runs

Installed by `setup.command` (or `scripts/install-launch-jobs.sh`) as launchd jobs named `<prefix>.<job>`, where the prefix is `POS_LABEL_PREFIX` in `config.sh`:

- `personal-os-sync`: at login and every 15 minutes. Backs up this repo to its private GitHub remote.
- `personal-os-maintenance`: at login and daily at 09:15. Forced sync plus the audit, recorded in a log.
- `vault-mirror` (optional): at login and every 30 minutes. One-way, markdown-only copy of your vault to Google Drive `My Drive/Vault-Mirror/`. Needs Google Drive for desktop.
- `~/bin/personal-os-agent` runs a forced sync before and after a local agent session.

The sync job fetches `origin/main`, accepts remote changes only when they fast-forward a clean checkout, runs the audit, waits until edited files have been quiet for two minutes, stages changes, runs `gitleaks`, commits, fetches again and pushes only when the remote is still an ancestor. It never force-pushes, rebases or resolves conflicts.

## Commands

```sh
# Loader, Git, job and log status
~/personal-os/scripts/status-personal-os-automation.sh

# Back up completed changes now
~/personal-os/scripts/sync-personal-os.sh --force

# Sync log stuck on DEFER all day: clear a stale session lock, then force a sync
~/personal-os/scripts/unstick-personal-os-sync.sh

# Re-install the background jobs after editing config.sh or a template
~/personal-os/scripts/install-launch-jobs.sh

# Run a local agent with a sync before and after
~/bin/personal-os-agent claude
~/bin/personal-os-agent codex

# Remove the background jobs and the launcher
~/personal-os/scripts/uninstall.sh
```

For another local command-line agent, configure it to read `~/.agents/AGENTS.md`. If it has no instruction-file support, give it `prompts/local-agent-bootstrap.md` as its startup prompt.

## Evidence and recovery

- Sync: `~/Library/Logs/personal-os-sync.log`
- Daily check: `~/Library/Logs/personal-os-maintenance.log`
- Vault mirror: `~/Library/Logs/vault-mirror.log`
- Real changes: your private GitHub commit history
- Explicit loader proofs: `knowledge/agent-checkins.md`

If a job reports divergence, a secret or an audit failure, it leaves the working tree and the remote untouched. Fix the reported condition, then run the forced sync above.

Log lines and what they mean:

| Line | Meaning |
|---|---|
| `NOCHANGE` | nothing to back up |
| `COMMIT` then `PUSH` | backed up |
| `DEFER \| a wrapped ... session is active` | a `personal-os-agent` session is open; it backs up when the session ends. All day long: run `unstick-personal-os-sync.sh` |
| `DEFER \| repository changed within the last two minutes` | waiting for you to stop typing |
| `FAIL \| gitleaks rejected staged changes` | something looked like a secret: remove it, then force a sync |
| `FAIL \| ... diverged` | GitHub has commits your Mac does not: resolve by hand (`git pull --rebase` when you are sure) |
