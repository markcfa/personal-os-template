#!/bin/sh
# maintain-personal-os.sh: daily health check. Runs a forced sync and the audit, and records
# both results in ~/Library/Logs/personal-os-maintenance.log.

set -u

canonical="${PERSONAL_OS_ROOT:-$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)}"
log_dir="$HOME/Library/Logs"
log_file="$log_dir/personal-os-maintenance.log"
mkdir -p "$log_dir"

stamp=$(date '+%Y-%m-%d %H:%M:%S %Z')
printf '%s | START | daily Personal OS maintenance\n' "$stamp" >> "$log_file"

if "$canonical/scripts/sync-personal-os.sh" --force >> "$log_file" 2>&1; then
  sync_result=PASS
else
  sync_result=FAIL
fi

if audit_output=$("$canonical/scripts/audit-personal-os.sh" 2>&1); then
  audit_result=PASS
else
  audit_result=FAIL
fi
printf '%s\n' "$audit_output" >> "$log_file"

head_ref=$(/usr/bin/git -C "$canonical" rev-parse --short HEAD 2>/dev/null || printf 'unknown')
stamp=$(date '+%Y-%m-%d %H:%M:%S %Z')
printf '%s | RESULT | sync=%s audit=%s head=%s\n' "$stamp" "$sync_result" "$audit_result" "$head_ref" | tee -a "$log_file"

[ "$sync_result" = PASS ] && [ "$audit_result" = PASS ]
