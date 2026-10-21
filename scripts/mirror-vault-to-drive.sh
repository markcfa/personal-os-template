#!/bin/sh
# mirror-vault-to-drive.sh: one-way, markdown-only copy of your notes vault into Google Drive, so
# cloud assistants (ChatGPT and Gemini through their Drive connections) can read your notes.
# Never writes to the vault. Skips the folders listed in POS_MIRROR_EXCLUDE (config.sh), hidden
# folders such as .obsidian and .trash, _to_delete/, *.bak-* files and anything not markdown.
# Deletions propagate (it is a mirror), but it refuses to run if Drive is not mounted or the
# vault looks empty, so a sync failure can never wipe the copy.
# Then it packs the same notes into about 25 bundles in Drive "Vault-Bundles/" for Gemini, which
# cannot read .md files: scripts/vault-docs.gs (a Google Apps Script) turns them into Google Docs.
# Set POS_BUNDLES=off in config.sh to skip the bundles.

set -eu

root="${PERSONAL_OS_ROOT:-$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)}"
if [ -f "$root/config.sh" ]; then . "$root/config.sh"; fi
log_file="$HOME/Library/Logs/vault-mirror.log"
lock_file="$HOME/Library/Caches/vault-mirror.lock"
mkdir -p "$HOME/Library/Logs" "$HOME/Library/Caches"

log() { printf '%s | %s\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')" "$*" | tee -a "$log_file"; }

if [ -z "${POS_VAULT_DIR:-}" ] || [ -z "${POS_DRIVE_ACCOUNT:-}" ]; then
  log "SKIP | vault mirror not configured (run setup.command)"
  exit 0
fi

src="$POS_VAULT_DIR"
drive="$HOME/Library/CloudStorage/GoogleDrive-$POS_DRIVE_ACCOUNT/My Drive"
dest="$drive/${POS_MIRROR_FOLDER:-Vault-Mirror}"
min_md="${POS_MIRROR_MIN:-20}"

if ! /usr/bin/shlock -f "$lock_file" -p "$$"; then
  log "SKIP | another mirror run holds the lock"
  exit 0
fi
trap 'rm -f "$lock_file"' EXIT

[ -d "$drive" ] || { log "FAIL | Google Drive for desktop is not mounted for $POS_DRIVE_ACCOUNT ($drive)"; exit 1; }
[ -d "$src" ] || { log "FAIL | vault missing: $src"; exit 1; }

found=$( { find "$src" -type f -name '*.md' 2>/dev/null || true; } | head -n "$min_md" | wc -l | tr -d ' ')
if [ "$found" -lt "$min_md" ]; then
  log "FAIL | fewer than $min_md markdown files in $src; mirror left untouched"
  exit 1
fi

rsync_bin=/usr/bin/rsync
if [ -x /opt/homebrew/bin/rsync ]; then rsync_bin=/opt/homebrew/bin/rsync; fi

set --
for d in ${POS_MIRROR_EXCLUDE:-}; do set -- "$@" "--exclude=/$d/"; done

mkdir -p "$dest"
if ! "$rsync_bin" -rt --delete "$@" \
  --exclude='.*/' --exclude='_to_delete/' --exclude='*.bak-*' --exclude='.DS_Store' \
  --include='*/' --include='*.md' --exclude='*' \
  "$src/" "$dest/" >/dev/null 2>>"$log_file"; then
  log "FAIL | rsync did not finish (details above); check the vault is fully downloaded"
  exit 1
fi

for d in ${POS_MIRROR_EXCLUDE:-}; do
  if [ -e "$dest/$d" ]; then
    log "FAIL | excluded folder $d found in the mirror; check POS_MIRROR_EXCLUDE"
    exit 1
  fi
done

copied=$( { find "$dest" -type f -name '*.md' 2>/dev/null || true; } | wc -l | tr -d ' ')
log "OK | mirror holds $copied markdown files ($rsync_bin)"

if [ "${POS_BUNDLES:-on}" = "off" ]; then
  exit 0
fi
bundles="$drive/${POS_BUNDLE_FOLDER:-Vault-Bundles}"
# shellcheck disable=SC2086 # POS_MIRROR_EXCLUDE is a space-separated list by design
if out=$(POS_BUNDLE_KEY_NOTES="${POS_BUNDLE_KEY_NOTES:-}" /usr/bin/python3 "$root/scripts/build-vault-bundles.py" \
    "$src" "$bundles" ${POS_MIRROR_EXCLUDE:-} 2>&1); then
  log "BUNDLES | $(printf '%s\n' "$out" | tail -n 1)"
else
  log "WARN | vault bundles failed, the mirror itself is fine: $(printf '%s\n' "$out" | tail -n 1)"
fi
