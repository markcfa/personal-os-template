#!/bin/bash
# personal-os → PRIVATE GitHub backup. Safe to re-run any time: commits + pushes whatever's new.
set -e
cd "$(dirname "$0")"
NAME="$(basename "$PWD")"
echo "== $NAME → private GitHub =="

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) is not installed. Install:  brew install gh   (or https://cli.github.com)"
  open "https://cli.github.com" 2>/dev/null || true
  exit 1
fi

gh auth status >/dev/null 2>&1 || gh auth login --web --hostname github.com

if [ ! -d .git ]; then
  git init -b main
fi

# Commit identity: use GitHub noreply email so your real address never lands in commits.
if ! git config user.email >/dev/null 2>&1 && ! git config --global user.email >/dev/null 2>&1; then
  LOGIN="$(gh api user -q .login)"
  REALNAME="$(gh api user -q .name)"
  git config user.name  "${REALNAME:-$LOGIN}"
  git config user.email "${LOGIN}@users.noreply.github.com"
fi

git add -A
git commit -m "$NAME: sync $(date +%F)" 2>/dev/null || echo "(nothing new to commit)"

if git remote get-url origin >/dev/null 2>&1; then
  git push -u origin main
else
  gh repo create "$NAME" --private --source=. --remote=origin --push
fi

echo "✅ Done — private repo '$NAME' is on GitHub."
