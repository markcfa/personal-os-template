#!/bin/sh
# audit-personal-os.sh: checks the agent loaders, Git health, write access and upstream state.
# Exits non-zero only on a FAIL; WARNs are informational.

set -eu

canonical="${PERSONAL_OS_ROOT:-$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)}"
if [ -f "$canonical/config.sh" ]; then . "$canonical/config.sh"; fi
expected="$canonical/AGENTS.md"
failures=0
warnings=0

pass() { printf 'PASS  %s\n' "$1"; }
warn() { printf 'WARN  %s\n' "$1"; warnings=$((warnings + 1)); }
fail() { printf 'FAIL  %s\n' "$1"; failures=$((failures + 1)); }

check_link() {
  label=$1
  path=$2
  if [ ! -L "$path" ]; then
    fail "$label is not a symlink: $path"
    return
  fi
  resolved=$(readlink "$path")
  case "$resolved" in
    "$expected") pass "$label -> $expected" ;;
    *) fail "$label resolves to $resolved, expected $expected" ;;
  esac
}

if [ -d "$canonical/.git" ]; then
  pass "canonical Git checkout exists at $canonical"
else
  fail "canonical Git checkout missing at $canonical"
fi

if [ -z "${POS_LOADERS:-}" ]; then
  warn "no agent loaders configured (run setup.command)"
fi
for loader in ${POS_LOADERS:-}; do
  case "$loader" in
    claude) check_link "Claude Code loader" "$HOME/.claude/CLAUDE.md" ;;
    codex) check_link "Codex loader" "$HOME/.codex/AGENTS.md" ;;
    agents) check_link "Generic cross-tool loader" "$HOME/.agents/AGENTS.md" ;;
    *) warn "unknown loader in POS_LOADERS: $loader" ;;
  esac
done

if grep -q 'POS-CANARY-CHANGE-ME' "$expected" 2>/dev/null; then
  warn "loader canary in AGENTS.md is still the placeholder (run setup.command)"
fi

probe="$canonical/.personal-os-write-test.$$"
if (umask 077 && : > "$probe") 2>/dev/null; then
  rm -f "$probe"
  pass "canonical repo is writable"
else
  fail "canonical repo is not writable"
fi

if git -C "$canonical" fsck --connectivity-only --no-dangling --no-progress >/dev/null 2>&1; then
  pass "Git object graph is connected"
else
  fail "Git object graph failed connectivity check"
fi

if [ -n "$(git -C "$canonical" status --porcelain)" ]; then
  warn "canonical repo has uncommitted changes"
else
  pass "canonical repo working tree is clean"
fi

head=$(git -C "$canonical" rev-parse HEAD 2>/dev/null || true)
tracking=$(git -C "$canonical" rev-parse '@{upstream}' 2>/dev/null || true)
if [ -z "$tracking" ]; then
  warn "no upstream tracking ref is configured"
elif [ "$head" = "$tracking" ]; then
  pass "local HEAD matches the fetched upstream ref"
else
  warn "local HEAD differs from the fetched upstream ref"
fi

printf '\nSummary: %s failure(s), %s warning(s)\n' "$failures" "$warnings"
[ "$failures" -eq 0 ]
