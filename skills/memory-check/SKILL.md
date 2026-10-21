---
name: memory-check
description: Prove that the current agent loaded the Personal OS instructions (AGENTS.md) and can read and write the shared repo. Use when the user says "memory check", "test shared memory", or asks whether this agent loaded the Personal OS.
---

# Cross-agent memory check

1. Before reading any file, report the loader canary already present in your startup context. The expected value is in `AGENTS.md`; do not read it from there as a substitute for startup loading.
2. Identify the instruction source reported by the client, if the client exposes it.
3. Read `AGENTS.md` and `MAP.md`; confirm the canary from step 1 matches the canonical file.
4. Run `scripts/audit-personal-os.sh` and report every PASS, WARN or FAIL faithfully.
5. Only if the user explicitly asked for a recorded check-in, append a dated line to `knowledge/agent-checkins.md`, then commit and push it. Otherwise leave the repo unchanged.

A canary read only after opening the file does not prove the loader worked: mark that result as inconclusive.
