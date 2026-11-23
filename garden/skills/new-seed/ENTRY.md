---
name: new-seed
description: "Builds, changes or retires a seed with the owner, one question at a time, and stages it on a local branch. Use when the router offers a new seed, rsi proposes one, or the owner asks to create, change or retire a bot."
metadata: { seeds-format: "1.0" }
---
# new-seed

Paths are relative to the garden root. The format is `garden/docs/SPEC.md`; examples are in `garden/skills/new-seed/examples/` (**examples, not required**: garden enforces no workflow format).

## Asking
- One question per message, as escalate's block with kind `question`: `bash garden/skills/escalate/block.sh --kind question --seed garden ...`. Your recommendation is the first option.
- Never ask what the task, the owner's words, the docs, memory or `memory/unrouted.md` already answer: draft it and ask the owner to confirm or change the draft instead.
- Keep a running draft and show it before the last question.

## New seed: topics, in order
1. **Purpose**, one sentence: "You are the <name>. You <purpose>." The name follows: lowercase, digits, single hyphens.
2. **`when`**: one line (≤ 200 characters) the router will match tasks against. Draft it from the task or the unrouted lines that led here, and check it against `seeds/INDEX.md`: it must not overlap an existing seed. Past 20 seeds, also its `group`.
3. **What it reads:** rules it needs that are not in the root docs become its own docs (`seeds/<name>/docs/` plus INDEX lines, `- [<file>](<file>): read when <condition>.`). Reuse root docs rather than copying them.
4. **Skills:** shared ones (`escalate`, `handoff`, `sync`, or the owner's own under `skills/`; never in `garden/`), bundled ones (written for this seed), `installed:<s>` (the owner installs it through its own channel), or a vendored copy (below). Required or optional. `memory` and `rsi` are implicit: never listed.
5. **Calls:** does it run other seeds, and in what order? If yes: `calls`, `handoff` in skills, and the order in the owner's words, in SEED.md or, if it is longer than a few lines, in `workflow.md` (name each called seed as `seed:<name>` in backticks). Offer `examples/task-manager/` as a starting point, never as a template to fill.
6. **`access`:** `read-only` (reads and reports: reviewers, auditors), `edit` (changes files but runs nothing), or `full` (the default). It is enforced when another seed calls this one (`garden/skills/handoff/access.md`).
7. **Asking the owner:** `escalate` in skills (it asks when stuck), or an `autonomy` fallback: `decide-and-record` or `stop-and-record`.
8. **Sync (optional):** should this seed sync the garden, and when ("at the end of every run", "when I say ship it")? If yes, add `sync` to its optional skills and write the moment into SEED.md in the owner's words. Recommend no sync unless the owner works on more than one machine or shares the garden.
9. **Seed memory:** facts the owner states that the seed should start with: MEMORY.md lines, written in the stage with `garden/skills/memory/write.py add ... --owner` (it scans them). Rules go to docs, not memory.

## Build it (in a stage, seeds tier)
Open the stage (`garden/skills/rsi/stage.md` §2), then write, inside it:
- `seeds/<name>/SEED.md`: the frontmatter from the answers, then the body (≤ 500 words): purpose, what it does in the owner's words (or `Follow [workflow.md](workflow.md).`), `Done when:`, `Never:`;
- `seeds/<name>/workflow.md` if topic 5 needs one;
- `seeds/<name>/docs/INDEX.md` (`# Docs`, then its lines) and its docs;
- `seeds/<name>/MEMORY.md` (`# Memory`, a blank line, the intro line from `garden/docs/SPEC.md` §6, then the seed lines) and `seeds/<name>/memory/runs.md` (`# Runs`);
- the line `- <name>: <when>` in `seeds/INDEX.md`, under its group heading if there are groups.

Then finish the stage (`garden/skills/rsi/stage.md` §3): validate, commit locally with the title `seeds(<name>): new seed` and a body listing the answers and their evidence (the owner's words, unrouted lines), remove the worktree, keep the branch. Tell the owner the branch name, and that the seed is live once the branch is merged: through its PR after `sync` (with an origin), or locally with `git merge <branch>` (without one). Never merge it yourself.

## Change a seed
The same topics, only those that change, asked the same way. Build the change in a stage. Keep `seeds/INDEX.md` equal to SEED.md (`when`, `group`), and each docs INDEX equal to its folder, in the same commit. Title: `seeds(<name>): <summary>`.

## Retire a seed
Ask once, naming what calls it (`calls` in other seeds). In a stage: delete `seeds/<name>/` and its INDEX line, remove it from every `calls` and `workflow.md` that names it, and move its MEMORY.md lines worth keeping into the root `memory/archive.md` (`~~<line>~~ · moved YYYY-MM-DD`) in the same commit. Title: `seeds(<name>): retire`.

## Vendoring a third-party skill
When the owner wants a copy rather than `installed:`, follow `garden/skills/new-seed/vendoring.md`.

## First run in an empty garden
If `seeds/INDEX.md` lists no seeds, offer to build the owner's first seed (start from the task in hand), and show the optional line the owner can add by hand to each tool's global instructions (`~/.claude/CLAUDE.md`, `~/.config/opencode/AGENTS.md`, `~/.pi/agent/AGENTS.md`, `~/.omp/agent/AGENTS.md`):
> Start every task with the `garden` skill, unless your prompt says you were called as a seed inside a running task.

Never add it yourself.
