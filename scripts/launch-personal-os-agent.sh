#!/bin/sh
# launch-personal-os-agent.sh: runs a local agent between two forced syncs, and holds a session
# lock so the 15-minute backup does not commit your half-finished changes mid-session.
# Usage: personal-os-agent {claude|codex|COMMAND} [arguments...]

set -u

canonical="${PERSONAL_OS_ROOT:-$(CDPATH='' cd -- "$(dirname -- "$(readlink "$0" 2>/dev/null || printf '%s' "$0")")/.." && pwd)}"
session_lock="$HOME/Library/Caches/personal-os-agent-session.lock"

if [ "$#" -lt 1 ]; then
  printf 'Usage: personal-os-agent {claude|codex|COMMAND} [arguments...]\n' >&2
  exit 2
fi

if ! "$canonical/scripts/sync-personal-os.sh" --force; then
  printf 'Personal OS pre-session sync failed; see ~/Library/Logs/personal-os-sync.log\n' >&2
  exit 1
fi

mkdir -p "$HOME/Library/Caches"
if ! /usr/bin/shlock -f "$session_lock" -p "$$"; then
  printf 'Another wrapped Personal OS agent session is active.\n' >&2
  exit 1
fi
cleanup() {
  rm -f "$session_lock"
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM

client=$1
shift
export PERSONAL_OS_ROOT="$canonical"
export PERSONAL_OS_INSTRUCTIONS="$HOME/.agents/AGENTS.md"

case "$client" in
  claude)
    command_path=$(command -v claude || printf '/opt/homebrew/bin/claude')
    "$command_path" "$@"
    client_status=$?
    ;;
  codex)
    # The ChatGPT app keeps Codex in Resources/codex-cli/bin/codex (older builds: Resources/codex).
    command_path=$(command -v codex || { for c in /Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex /Applications/ChatGPT.app/Contents/Resources/codex; do [ -x "$c" ] && { printf '%s' "$c"; break; }; done; } || true)
    [ -n "$command_path" ] || command_path=codex
    "$command_path" "$@"
    client_status=$?
    ;;
  *)
    printf 'This client must load %s. Bootstrap prompt: %s\n' \
      "$PERSONAL_OS_INSTRUCTIONS" "$canonical/prompts/local-agent-bootstrap.md"
    "$client" "$@"
    client_status=$?
    ;;
esac

cleanup
if ! "$canonical/scripts/sync-personal-os.sh" --force; then
  printf 'Personal OS post-session sync failed; see ~/Library/Logs/personal-os-sync.log\n' >&2
  [ "$client_status" -ne 0 ] && exit "$client_status"
  exit 1
fi

exit "$client_status"
