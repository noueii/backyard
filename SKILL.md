---
name: backyard
description: "Your bots (seeds) for software work. Routes every task (feature, fix, refactor, review, docs, chores, questions about code) to the seed that fits, with its rules and memory, or handles a one-off directly. Use when starting any software task, before acting on it."
metadata:
  seeds-format: "2.0"
  version: "4.0.0"
---
# backyard

Every path here is relative to the folder this SKILL.md is in (the backyard root). The framework is in `backyard/`; everything else is the owner's. The skills inside (backyard's `backyard-*` in `backyard/skills/`, the owner's in `skills/` and `seeds/<x>/skills/`) are `SKILL.md` files you read by path when this router or a seed says to; never start one on its own, even if your tool lists it.

## Called seeds
If your prompt says you were called as seed `<x>` (by handoff), do not route: run the hand-over below for `seeds/<x>/SEED.md`, with the differences that prompt states, and return your report.

## Read first
`docs/INDEX.md` (the owner's rules for every task) and `seeds/INDEX.md` (one line per seed: `- <name>: <when>`). Under `## <group>` headings, read the group lines first, then only the seeds under groups that fit.

## Route
1. The owner names a seed ("use reviewer"): hand over to it.
2. Otherwise keep the seeds whose `when` fits the task. One fits: hand over. Several: take the most specific; still a tie, ask once, naming both (escalate's block, kind `route`: `bash backyard/skills/backyard-escalate/block.sh`).
3. None fits:
   - a one-off: handle it directly (below);
   - a repeatable task: offer `backyard-new-seed` once (block kind `question`, "handle it directly this time" first);
   - unsure: treat it as a one-off.

## Hand over
1. **Start memory:** read `backyard/skills/backyard-memory/SKILL.md`, then `memory/INDEX.md` and `seeds/<x>/memory/INDEX.md`, then `seeds/<x>/docs/INDEX.md`. Its docs override the root's.
2. **Become the seed:** read `seeds/<x>/SEED.md` and every required skill's `SKILL.md` (`backyard/skills/<s>/`, `skills/<s>/` or `seeds/<x>/skills/<s>/`; an `installed:<s>` skill the way your tool loads skills). A missing required skill stops here: escalate, or follow `autonomy`. If `access` is not `full`, keep to it in the work: no file edits for `read-only`, no shell for either (memory's own commands excepted).
3. **Work:** follow SEED.md, and `workflow.md` if it links one. Capture memory only when something is worth it (backyard-memory's SKILL.md says what). Open a doc or memory file only when its "read when" fits.
4. **End:** do what memory's "End of the task" says (a retro if due, the stages, the local memory commit). Sync only if the seed's text says to (`backyard/skills/backyard-sync/SKILL.md`). Then report: escalate's format if the seed uses escalate, otherwise a short "done / decided / open" list.

## One-off
Handle it under the root docs and the root `memory/INDEX.md`. If it looks repeatable and no seed fits, capture a pending memory in `memory/` (`backyard/skills/backyard-memory/SKILL.md`), such as `no-seed-for-<kind>`: seen again, it is the evidence for proposing a new seed. Plain questions and true one-offs write nothing.

## Changes to the backyard
Change seeds, docs and skills only through `backyard-new-seed` or memory's stage (`backyard/skills/backyard-memory/stage.md`), which put them on a branch. Never hand-edit the live clone, except memory. Pushing and pulling is `backyard-sync`'s job, run only when a seed says so or the owner asks. The format is `backyard/docs/SPEC.md`; check with `python3 backyard/check/validate.py .`.
