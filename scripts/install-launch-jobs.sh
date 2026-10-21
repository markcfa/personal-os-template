#!/bin/sh
# install-launch-jobs.sh: renders launchd/*.plist.template with your settings, installs the copies
# in ~/Library/LaunchAgents and (re)loads them. setup.command runs it; re-run it yourself after
# changing config.sh or a template.

set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
if [ ! -f "$root/config.sh" ]; then
  echo "No config.sh yet: run setup.command first."
  exit 1
fi
. "$root/config.sh"

agents="$HOME/Library/LaunchAgents"
mkdir -p "$agents" "$HOME/Library/Logs"

jobs=""
if git -C "$root" remote get-url origin >/dev/null 2>&1; then
  jobs="personal-os-sync personal-os-maintenance"
else
  echo "No GitHub remote yet, so the backup jobs are not installed. Add one (see README), then run this again."
fi
if [ -n "${POS_VAULT_DIR:-}" ] && [ -n "${POS_DRIVE_ACCOUNT:-}" ]; then
  jobs="$jobs vault-mirror"
fi

for job in $jobs; do
  label="$POS_LABEL_PREFIX.$job"
  dst="$agents/$label.plist"
  sed -e "s|__LABEL__|$label|g" -e "s|__ROOT__|$root|g" -e "s|__HOME__|$HOME|g" \
    "$root/launchd/$job.plist.template" > "$dst"
  plutil -lint "$dst" >/dev/null
  launchctl bootout "gui/$(id -u)" "$dst" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$dst"
  echo "installed and started: $label"
done
