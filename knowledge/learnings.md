# Learnings and dead ends

Record what didn't work and what bit you, so no agent retries or re-trips it. Date each entry.

These first entries come from the system this template was extracted from:

- **Automatic Git must fail closed.** Never make a scheduled job rebase, resolve conflicts, bypass secret scanning or force-push. Preserve local work and log the condition for a human or agent to resolve.
- **A loader is not model memory.** Local, filesystem-aware clients can receive this repo at startup; ordinary cloud chats cannot see Mac files without an explicit connection.
- **A shared repo is not ambient memory by itself.** Each client needs a global loader pointing at the canonical file, and a fresh-session canary test to prove it loaded. Opening an unrelated project does not load a sibling repo's AGENTS.md.
- **Loader copies drift.** Separate instruction files for each tool end up with different paths and facts. Link every loader to one canonical file; never maintain copies.
- **Do not keep a live Git repository in a cloud-synced folder** such as iCloud's Documents. Sync conflicts leave duplicate object files (` 2`, ` 3`). Keep the checkout somewhere local, such as `~/personal-os`.
- **Verify paths on disk before writing them down.** Documented paths that no longer exist send every agent the wrong way.
- **Maintenance evidence should reflect real work.** Log routine checks locally and commit only real content changes; empty daily commits are noise, not evidence.
- **A long-open agent session quietly turns the 15-minute backup into a daily one.** The sync defers while the session lock is held by a live process. Read the sync log before calling the sync broken; `scripts/unstick-personal-os-sync.sh` clears the lock only when it is stale.
