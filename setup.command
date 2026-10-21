#!/bin/sh
# setup.command: first-run setup for your Personal OS. Double-click it in Finder, or run it in
# Terminal. Safe to re-run: your previous answers are offered as defaults.
#
# What it does: writes config.sh (your settings, never committed), sets your Git identity, gives
# AGENTS.md a unique loader canary, optionally points Claude Code, Codex and other local agents at
# AGENTS.md (backing up whatever was there), installs ~/bin/personal-os-agent, and installs the
# background jobs (backup every 15 minutes, daily check, optional vault mirror every 30 minutes).

set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
cd "$root"
today=$(date +%Y%m%d)

say() { printf '%s\n' "$*"; }
ask() {
  printf '%s [%s]: ' "$2" "$3"
  read -r reply || reply=""
  [ -n "$reply" ] || reply=$3
  eval "$1=\$reply"
}
confirm() {
  printf '%s [Y/n]: ' "$1"
  read -r reply || reply=""
  case "$reply" in [Nn]*) return 1 ;; *) return 0 ;; esac
}
quote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"; }
# shellcheck disable=SC2088  # the literal ~ is matched on purpose
expand_home() { case "$1" in "~") printf '%s' "$HOME" ;; "~/"*) printf '%s/%s' "$HOME" "${1#\~/}" ;; *) printf '%s' "$1" ;; esac; }

say "Personal OS setup"
say "-----------------"

if [ "$(uname -s)" != Darwin ]; then
  say "This setup is for macOS (it uses launchd for the background jobs)."
  exit 1
fi
if ! command -v git >/dev/null 2>&1; then
  say "Git is missing. Run  xcode-select --install  then run this again."
  exit 1
fi
if ! command -v gitleaks >/dev/null 2>&1; then
  say "gitleaks is missing. The backup job refuses to commit without it, so no secret reaches GitHub."
  say "Install it with Homebrew (https://brew.sh):  brew install gitleaks   then run this again."
  exit 1
fi

POS_NAME=""; POS_EMAIL=""; POS_LABEL_PREFIX="com.$(id -un)"; POS_VAULT_DIR=""
POS_DRIVE_ACCOUNT=""; POS_MIRROR_EXCLUDE="Private.nosync"; POS_LOADERS=""
if [ -f config.sh ]; then . ./config.sh; fi

default_name=${POS_NAME:-$(id -F 2>/dev/null || id -un)}
ask POS_NAME "Your name (for Git commits)" "$default_name"
ask POS_EMAIL "Email for Git commits (one that is on your GitHub account)" "$POS_EMAIL"

default_vault=$POS_VAULT_DIR
if [ -z "$default_vault" ] && [ -d "$HOME/Documents/Obsidian" ]; then default_vault="$HOME/Documents/Obsidian"; fi
ask POS_VAULT_DIR "Notes vault to mirror to Google Drive (blank to skip the mirror)" "$default_vault"
POS_VAULT_DIR=$(expand_home "$POS_VAULT_DIR")
if [ -n "$POS_VAULT_DIR" ] && [ ! -d "$POS_VAULT_DIR" ]; then
  say "Not a folder: $POS_VAULT_DIR. Skipping the mirror for now."
  POS_VAULT_DIR=""
fi
if [ -n "$POS_VAULT_DIR" ]; then
  ask POS_DRIVE_ACCOUNT "Google account signed in to Google Drive for desktop" "$POS_DRIVE_ACCOUNT"
  ask POS_MIRROR_EXCLUDE "Vault folders never to copy (top level, space-separated, no spaces in names)" "$POS_MIRROR_EXCLUDE"
  if [ -n "$POS_DRIVE_ACCOUNT" ] && [ ! -d "$HOME/Library/CloudStorage/GoogleDrive-$POS_DRIVE_ACCOUNT/My Drive" ]; then
    say "Google Drive for desktop is not set up for $POS_DRIVE_ACCOUNT yet. Install it from"
    say "https://www.google.com/drive/download/ , sign in, then run this setup again."
    POS_DRIVE_ACCOUNT=""
  fi
fi
ask POS_LABEL_PREFIX "Name prefix for the background jobs" "$POS_LABEL_PREFIX"

[ -d .git ] || git init -q -b main
git config user.name "$POS_NAME"
if [ -n "$POS_EMAIL" ]; then git config user.email "$POS_EMAIL"; fi

if git remote get-url origin >/dev/null 2>&1; then
  origin=$(git remote get-url origin)
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    visibility=$(gh repo view "$origin" --json visibility -q .visibility 2>/dev/null || true)
    if [ "$visibility" = PUBLIC ]; then
      say "STOP: your remote ($origin) is PUBLIC. This repo will hold your personal notes."
      say "Make it private ( gh repo edit $origin --visibility private --accept-visibility-change-consequences )"
      say "or point origin at a private repo, then run this again."
      exit 1
    fi
  else
    say "Check that $origin is a PRIVATE repository: this repo will hold your personal notes."
  fi
elif command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  if confirm "No GitHub remote yet. Create a private repository and push to it now?"; then
    git add -A
    git commit -q -m "Set up Personal OS" || true
    gh repo create "$(basename "$root")" --private --source=. --remote=origin --push
  fi
else
  say "No GitHub remote yet. Install the GitHub CLI ( brew install gh ), run  gh auth login ,"
  say "then run this again to create a private repository. Until then the backup jobs stay off."
fi

if grep -q 'POS-CANARY-CHANGE-ME' AGENTS.md; then
  canary="POS-$(LC_ALL=C tr -dc 'A-Z0-9' < /dev/urandom | head -c 6)-$today"
  tmp=$(mktemp)
  sed "s/POS-CANARY-CHANGE-ME/$canary/" AGENTS.md > "$tmp" && cat "$tmp" > AGENTS.md && rm -f "$tmp"
  say "Loader canary set in AGENTS.md: $canary"
fi

if confirm "Point Claude Code, Codex and other local agents at this AGENTS.md? (anything already there is backed up)"; then
  POS_LOADERS="claude codex agents"
  for target in "$HOME/.claude/CLAUDE.md" "$HOME/.codex/AGENTS.md" "$HOME/.agents/AGENTS.md"; do
    mkdir -p "$(dirname "$target")"
    if [ -L "$target" ] && [ "$(readlink "$target")" = "$root/AGENTS.md" ]; then
      say "already linked: $target"
      continue
    fi
    if [ -e "$target" ] || [ -L "$target" ]; then
      mv "$target" "$target.bak-$today-personal-os"
      say "backed up: $target -> $target.bak-$today-personal-os"
    fi
    ln -s "$root/AGENTS.md" "$target"
    say "linked: $target -> $root/AGENTS.md"
  done
fi

umask 077
{
  printf '# config.sh: your Personal OS settings. Written by setup.command; never committed to Git.\n'
  printf 'POS_NAME=%s\n' "$(quote "$POS_NAME")"
  printf 'POS_EMAIL=%s\n' "$(quote "$POS_EMAIL")"
  printf 'POS_LABEL_PREFIX=%s\n' "$(quote "$POS_LABEL_PREFIX")"
  printf 'POS_VAULT_DIR=%s\n' "$(quote "$POS_VAULT_DIR")"
  printf 'POS_DRIVE_ACCOUNT=%s\n' "$(quote "$POS_DRIVE_ACCOUNT")"
  printf 'POS_MIRROR_EXCLUDE=%s\n' "$(quote "$POS_MIRROR_EXCLUDE")"
  printf 'POS_LOADERS=%s\n' "$(quote "$POS_LOADERS")"
} > config.sh
umask 022
say "Saved your settings to config.sh"

chmod +x setup.command scripts/*.sh
mkdir -p "$HOME/bin"
ln -sfn "$root/scripts/launch-personal-os-agent.sh" "$HOME/bin/personal-os-agent"
case ":$PATH:" in
  *":$HOME/bin:"*) ;;
  *) say "Tip: add ~/bin to your PATH so you can type  personal-os-agent claude  from anywhere." ;;
esac

sh "$root/scripts/install-launch-jobs.sh"
sleep 5

say ""
say "Checking everything:"
sh "$root/scripts/status-personal-os-automation.sh" || true

say ""
say "Next:"
say "  1. Edit AGENTS.md (Who I am, How to work, Systems) and MAP.md."
say "  2. Fill in prompts/cloud-llm-context.md and prompts/cloud-llm-context-short.md."
say "  3. Connect your cloud assistants: docs/connect-cloud-assistants.md"
