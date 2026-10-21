#!/bin/sh
# uninstall.sh: stops and removes this Personal OS's launch jobs and the ~/bin/personal-os-agent
# link. Leaves your files, your repo, your Drive mirror and your agent loaders alone.

set -u

root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
if [ -f "$root/config.sh" ]; then . "$root/config.sh"; fi
prefix="${POS_LABEL_PREFIX:-com.$(id -un)}"

for job in personal-os-sync personal-os-maintenance vault-mirror; do
  dst="$HOME/Library/LaunchAgents/$prefix.$job.plist"
  [ -e "$dst" ] || continue
  launchctl bootout "gui/$(id -u)" "$dst" 2>/dev/null || true
  rm -f "$dst" && echo "removed launch job: $prefix.$job"
done

if [ -L "$HOME/bin/personal-os-agent" ]; then
  rm -f "$HOME/bin/personal-os-agent" && echo "removed: ~/bin/personal-os-agent"
fi

echo "Agent loaders (~/.claude/CLAUDE.md, ~/.codex/AGENTS.md, ~/.agents/AGENTS.md) were left in place."
echo "Any file setup replaced was saved next to it as <name>.bak-<date>-personal-os: move it back to restore."
