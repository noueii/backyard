---
name: garden
description: "Your bots (seeds) for software work. Routes every task (feature, fix, refactor, review, docs, chores, questions about code) to the seed that fits, with its rules and memory, or handles a one-off directly. Use when starting any software task, before acting on it."
metadata:
  seeds-format: "1.0"
  version: "1.0.0"
---
# garden

Every path here is relative to the folder this SKILL.md is in (the garden root). Internal skills are `ENTRY.md` files: read them by path; they are never in your skill list.

## Called seeds
If your prompt says you were called as seed `<x>` (by handoff), do not route: run the hand-over below for `seeds/<x>/SEED.md`, with the differences that prompt states, and return your report.

## Read first
`docs/INDEX.md` (the owner's rules for every task) and `seeds/INDEX.md` (one line per seed: `- <name>: <when>`). Under `## <group>` headings, read the group lines first, then only the seeds under groups that fit.

## Route
1. The owner names a seed ("use reviewer"): hand over to it.
2. Otherwise keep the seeds whose `when` fits the task. One fits: hand over. Several: take the most specific; still a tie, ask once, naming both (escalate's block, kind `route`: `bash skills/escalate/block.sh`).
3. None fits:
   - a one-off: handle it directly (below);
   - a repeatable task: offer `new-seed` once (block kind `question`, "handle it directly this time" first);
   - unsure: treat it as a one-off.

## Hand over
1. **Start memory:** read `skills/memory/ENTRY.md`, then `MEMORY.md` and `seeds/<x>/MEMORY.md`, then `seeds/<x>/docs/INDEX.md`. Its docs override the root's.
2. **Become the seed:** read `seeds/<x>/SEED.md` and every required skill's `ENTRY.md` (`skills/<s>/` or `seeds/<x>/skills/<s>/`; an `installed:<s>` skill the way your tool loads skills). A missing required skill stops here: escalate, or follow `autonomy`. If `access` is not `full`, keep to it in the work: no file edits for `read-only`, no shell for either (memory and rsi's own commands excepted).
3. **Work:** follow SEED.md, and `workflow.md` if it links one. Write memory as you go. Open a doc only when its "read when" fits.
4. **End:** read `skills/rsi/ENTRY.md` and do what it says (the run line, a retro if due, the local memory commit and stage). Sync only if the seed's text says to (`skills/sync/ENTRY.md`). Then report: escalate's format if the seed uses escalate, otherwise a short "done / decided / open" list.

## One-off
Handle it under the root docs. Unless it was a plain question, add a line to `memory/unrouted.md` with `python3 skills/memory/write.py add` (format in `spec/SPEC.md` §6); it is the evidence for proposing new seeds.

## Changes to the garden
Change seeds, docs and skills only through `new-seed` or `rsi`, which stage them on a branch. Never hand-edit the live clone, except memory. Pushing and pulling is `sync`'s job, run only when a seed says so or the owner asks. The format is `spec/SPEC.md`; check with `python3 check/validate.py .`.
