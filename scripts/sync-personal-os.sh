#!/bin/sh
# sync-personal-os.sh: guarded backup of this repo to its private GitHub remote.
# Fetches origin/main, fast-forwards a clean checkout, runs the audit, waits until edits have
# been quiet for two minutes, scans staged changes with gitleaks, commits and pushes.
# It never force-pushes, rebases or resolves conflicts: on any doubt it stops and logs why.
# Usage: sync-personal-os.sh [--force]   (--force skips the quiet wait and the session deferral)

set -u

canonical="${PERSONAL_OS_ROOT:-$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)}"
log_dir="$HOME/Library/Logs"
log_file="$log_dir/personal-os-sync.log"
lock_dir="$HOME/Library/Caches"
lock_file="$lock_dir/personal-os-sync.lock"
agent_session_lock="$lock_dir/personal-os-agent-session.lock"
git_bin="${GIT_BIN:-/usr/bin/git}"
force=0

if [ "${1:-}" = "--force" ]; then
  force=1
elif [ "$#" -gt 0 ]; then
  printf 'Usage: %s [--force]\n' "$0" >&2
  exit 2
fi

mkdir -p "$log_dir" "$lock_dir"

log() {
  line="$(date '+%Y-%m-%d %H:%M:%S %Z') | $*"
  printf '%s\n' "$line"
  printf '%s\n' "$line" >> "$log_file"
}

fail() {
  log "FAIL | $*"
  exit 1
}

# Check the session lock by hand: `shlock -f` without -p can report a lock as held after the file is
# gone, which made this job defer forever. A session counts only if the lock names a live
# personal-os-agent process, and a session that has left the repo untouched for an hour no longer
# blocks the backup.
session_active() {
  [ -f "$agent_session_lock" ] || return 1
  pid=$(tr -dc '0-9' < "$agent_session_lock")
  [ -n "$pid" ] || return 1
  kill -0 "$pid" 2>/dev/null || return 1
  ps -o command= -p "$pid" 2>/dev/null | grep -q 'personal-os-agent' || return 1
  return 0
}
if [ "$force" -eq 0 ] && session_active; then
  busy=$(find "$canonical" -path "$canonical/.git" -prune -o -name '*.bak-*' -prune -o \
    -name '.DS_Store' -prune -o -type f -mmin -60 -print -quit 2>/dev/null)
  if [ -n "$busy" ]; then
    log "DEFER | agent session (PID $pid) is open and the repo changed in the last hour"
    exit 0
  fi
  log "NOTE | an agent session is open but the repo has been idle for an hour; backing up anyway"
fi

if ! /usr/bin/shlock -f "$lock_file" -p "$$"; then
  log "SKIP | another Personal OS sync process holds the lock"
  exit 0
fi
cleanup() {
  rm -f "$lock_file"
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM

[ -d "$canonical/.git" ] || fail "canonical Git checkout missing: $canonical"
[ -x "$canonical/scripts/audit-personal-os.sh" ] || fail "audit script missing or not executable"
[ -x "$git_bin" ] || fail "Git executable missing: $git_bin"

cd "$canonical" || fail "cannot enter canonical checkout"

if ! "$git_bin" fetch --quiet origin main; then
  fail "git fetch origin main failed"
fi

head_ref=$("$git_bin" rev-parse HEAD) || fail "cannot resolve local HEAD"
remote_ref=$("$git_bin" rev-parse origin/main) || fail "cannot resolve origin/main"
ahead=0

if [ "$head_ref" != "$remote_ref" ]; then
  merge_base=$("$git_bin" merge-base HEAD origin/main) || fail "cannot find merge base"
  if [ "$merge_base" = "$head_ref" ]; then
    if [ -n "$("$git_bin" status --porcelain --untracked-files=all)" ]; then
      fail "remote is ahead while local changes exist; refusing automatic integration"
    fi
    if ! "$git_bin" merge --ff-only --quiet origin/main; then
      fail "fast-forward merge failed"
    fi
    log "PULL | fast-forwarded to $("$git_bin" rev-parse --short HEAD)"
  elif [ "$merge_base" = "$remote_ref" ]; then
    ahead=1
  else
    fail "local and remote histories diverged; manual resolution required"
  fi
fi

audit_output=$("$canonical/scripts/audit-personal-os.sh" 2>&1)
audit_status=$?
audit_summary=$(printf '%s\n' "$audit_output" | tail -n 1)
if [ "$audit_status" -ne 0 ]; then
  printf '%s\n' "$audit_output" >> "$log_file"
  fail "audit failed: $audit_summary"
fi
log "AUDIT | $audit_summary"

changes=$("$git_bin" status --porcelain --untracked-files=all)
if [ -n "$changes" ] && [ "$force" -eq 0 ]; then
  recent=$(find "$canonical" \
    -path "$canonical/.git" -prune -o \
    -name '*.bak-*' -prune -o \
    -name '.DS_Store' -prune -o \
    -type f -mmin -2 -print | head -n 1)
  if [ -n "$recent" ]; then
    log "DEFER | repository changed within the last two minutes"
    exit 0
  fi
fi

if [ -n "$changes" ]; then
  "$git_bin" add -A || fail "git add failed"
  if ! command -v gitleaks >/dev/null 2>&1; then
    "$git_bin" reset --quiet
    fail "gitleaks is unavailable; refusing automatic commit"
  fi
  if ! gitleaks protect --staged --redact --no-banner; then
    "$git_bin" reset --quiet
    fail "gitleaks rejected staged changes"
  fi
  if ! "$git_bin" diff --cached --check; then
    "$git_bin" reset --quiet
    fail "staged changes failed git diff --check"
  fi
  stamp=$(date '+%Y-%m-%d %H:%M %Z')
  if ! "$git_bin" commit -m "Back up Personal OS changes ($stamp)"; then
    fail "git commit failed"
  fi
  log "COMMIT | $("$git_bin" rev-parse --short HEAD)"
  ahead=1
fi

if [ "$ahead" -eq 0 ]; then
  log "NOCHANGE | local checkout already matches origin/main"
  exit 0
fi

if ! "$git_bin" fetch --quiet origin main; then
  fail "final git fetch failed; local commit preserved"
fi
if ! "$git_bin" merge-base --is-ancestor origin/main HEAD; then
  fail "remote changed incompatibly before push; local commit preserved"
fi
if ! "$git_bin" push origin HEAD:main; then
  fail "git push failed; local commit preserved"
fi
log "PUSH | origin/main now $("$git_bin" rev-parse --short HEAD)"
