#!/bin/sh
# unstick-personal-os-sync.sh: use when the sync log says DEFER all day. The 15-minute sync defers
# while the agent-session lock is held by a live process. If that process really is a
# personal-os-agent session, this says so and stops. Otherwise the session ended without cleaning
# up and the process ID was reused: it removes the lock and runs a forced sync.

set -u

root="${PERSONAL_OS_ROOT:-$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)}"
lock="$HOME/Library/Caches/personal-os-agent-session.lock"
sync="$root/scripts/sync-personal-os.sh"

if [ ! -e "$lock" ]; then
  echo "No session lock. Running a forced sync."
  exec "$sync" --force
fi

pid=$(tr -dc '0-9' < "$lock")
cmd=$(ps -o command= -p "${pid:-0}" 2>/dev/null || true)
started=$(ps -o lstart= -p "${pid:-0}" 2>/dev/null || true)

case "$cmd" in
  *personal-os-agent*)
    echo "A wrapped agent session is still open: PID $pid, started $started"
    echo "  $cmd"
    echo "Exit that session (type /exit in its Terminal tab), then run this again."
    exit 1
    ;;
esac

echo "Stale lock: PID ${pid:-none} is ${cmd:-not running} (not a personal-os-agent session)."
rm -f "$lock" && echo "Removed the stale lock."
exec "$sync" --force
