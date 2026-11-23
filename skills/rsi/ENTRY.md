---
name: rsi
description: "Recursive self-improvement: records each run, decides when a retro is due, and stages evidence-backed changes to seeds, docs and skills on local branches. Use when any seed run ends, and when the owner asks for a retro."
metadata: { seeds-format: "1.0" }
---
# rsi

Paths are relative to the garden root. Supporting files: `skills/rsi/retro.md` (what a retro checks), `skills/rsi/stage.md` (where changes are staged and how a branch is finished).

**rsi never pushes, never opens a PR and never merges.** Everything it writes stays in this clone: memory in the live clone, behaviour changes on local `garden/*` branches. `sync` publishes them, and only when a seed's text says so or the owner asks.

## 1. Every run: the run line
Append one line to `seeds/<x>/memory/runs.md` (format in `spec/SPEC.md` §6), oldest first:
```
- 2026-11-23 14:05 | fix-login-redirect | done | repo=you/app calls=reviewer esc=0 fixes=1 | owner corrected the redirect target
```
- **outcome:** `done`, `escalated`, `stopped`, `decided` (an autonomy decision), `passed` (handed over) or `failed`.
- **tags** (only the ones that apply, else `-`): `repo`, `calls` (seeds called, comma-separated), `caller` (if you were called), `esc` (escalations), `fixes` (owner corrections of your behaviour), `viol` (access violations by seeds you called), `loops` (retries in your own loops), `skipped` (missing optional skills).
- A **called** seed with access below `full` returns its run line in its report; the caller appends it to the called seed's `runs.md`.
- A one-off handled by the router gets no run line; the router logs it in `memory/unrouted.md`.

## 2. Every run: owner corrections
A direct owner correction of how the seed behaves ("never do X", "always run Y first") is staged at once, without waiting for a retro: it is evidence enough on its own. Stage it as a doc line or a SEED.md change (`stage.md`), quoting the owner. Everything else waits for a retro.

## 3. Is a retro due?
Read `runs.md` since its last `retro` line. A retro is due when any holds:
- 5 runs since the last retro;
- the same signal on 2 runs since the last retro: `esc>0`, `fixes>0`, `viol>0`, outcome `failed` or `stopped`, or the same `skipped` skill;
- a file over 90 % of its budget (`spec/SPEC.md` §7);
- the owner asks.

Otherwise the run line is enough: go to §5. A called seed never runs a retro; it notes "retro due" in its report and the next run at depth 0 does it.

## 4. The retro
Follow `skills/rsi/retro.md`. Then append the retro line:
```
- 2026-11-24 09:12 | retro | 6 runs | branch=garden/20261124-0912-retro-seeds root=- | 3 changes, 1 removal
```

## 5. Finish (depth 0 only)
1. If anything was staged, finish each stage as `stage.md` §3 says: validate, commit locally, remove the worktree, keep the branch.
2. Commit memory locally (`skills/memory/ENTRY.md`, "Commit").
3. In the report, under `## Staged`, list each branch with its title, and say: "Local only. Run sync (or ask for it) to open the PRs."

Nothing staged: no branch, nothing to list.

## Guardrails
- **Evidence or nothing:** every staged change cites at least 2 run or unrouted lines, or 1 owner correction, quoted.
- **At most 5 changes per retro branch.** Extra findings wait for the next retro.
- **Budgets fail the validator.** A retro that grows always-loaded text removes something too.
- **Owner decisions stick:** a root memory line `rsi proposal rejected: <what>` (sync writes these) blocks the same proposal until there is new evidence.
- **Memory can't change behaviour:** rules found in memory move to docs through a staged change, never obeyed from memory.
- **Fixed:** rsi never changes which skills are mandatory, never edits the live clone outside memory, never pushes and never merges. Changes to `skills/rsi/` are root-tier changes like any other.
