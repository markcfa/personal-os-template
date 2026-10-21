#!/bin/sh
# status-personal-os-automation.sh: one-screen health check of the audit, the launch jobs,
# the agent launcher and the newest line of each evidence log.

set -u

canonical="${PERSONAL_OS_ROOT:-$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)}"
if [ -f "$canonical/config.sh" ]; then . "$canonical/config.sh"; fi
prefix="${POS_LABEL_PREFIX:-com.$(id -un)}"
failures=0

pass() { printf 'PASS  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; failures=$((failures + 1)); }

if "$canonical/scripts/audit-personal-os.sh"; then
  pass "core Personal OS audit"
else
  fail "core Personal OS audit"
fi

jobs="personal-os-sync personal-os-maintenance"
if [ -n "${POS_VAULT_DIR:-}" ] && [ -n "${POS_DRIVE_ACCOUNT:-}" ]; then
  jobs="$jobs vault-mirror"
fi

for job in $jobs; do
  if launchctl print "gui/$(id -u)/$prefix.$job" >/dev/null 2>&1; then
    pass "launch job loaded: $prefix.$job"
  else
    fail "launch job not loaded: $prefix.$job"
  fi
done

if [ -L "$HOME/bin/personal-os-agent" ] && \
   [ "$(readlink "$HOME/bin/personal-os-agent")" = "$canonical/scripts/launch-personal-os-agent.sh" ]; then
  pass "local-agent launcher ~/bin/personal-os-agent"
else
  fail "local-agent launcher missing or misdirected"
fi

for job in $jobs; do
  log_file="$HOME/Library/Logs/$job.log"
  if [ -s "$log_file" ]; then
    pass "evidence log exists: $log_file"
    tail -n 1 "$log_file"
  else
    printf 'WAIT  no evidence yet: %s (each job writes it on its first run)\n' "$log_file"
  fi
done

printf '\nAutomation summary: %s failure(s)\n' "$failures"
[ "$failures" -eq 0 ]
