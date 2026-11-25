# The retro

Loaded at the end of a depth-0 task, only when a retro is due (`garden/skills/garden-memory/SKILL.md`, "End of the task"): a pending memory was seen again, a memory budget passed 80 %, or the owner asked. Adapted from mattpocock's `retro`.

## Read first
- Both memory folders (`memory/` and `seeds/<x>/memory/`): INDEX.md, the committed files, and every pending file.
- `memory/rejected.md`: never re-propose a line there without new evidence.
- This task's owner corrections, escalations and failures.
- What changed since the last retro: `git log --format='%h %cs %s' --since=<date of the last "memory: retro" commit> -- seeds/<x> memory` (find it with `git log -1 --format=%cs --grep='^memory: retro'`).
- The sizes of everything always loaded: the router, `docs/INDEX.md`, `seeds/INDEX.md`, both memory INDEX.md, this SEED.md (`python3 garden/skills/garden-memory/write.py check <memory folder>` for memory).
- The existing docs, before proposing a rule, so a finding is "the existing rule is unclear" rather than a duplicate.

## 1. Promotion
For each pending memory seen by 2 tasks (`seen` has two entries):
- **A fact, decision, preference or lesson** that still holds (check it if you can): `python3 garden/skills/garden-memory/write.py promote <pending file> --when "<condition>"` (`--top` if it matters more than what is there). It moves to `committed/` and gets its INDEX line.
- **Really a rule** ("run X before Y", "never Z"): don't promote it. Stage it as a doc line (`garden/skills/garden-memory/stage.md`), citing the pending file and its two tasks, then `remove` the pending file.
- **No longer true:** `remove` it.

## 2. Findings
Each names its **evidence** (memory files by name with their `seen` tasks, or an owner quote) and its **category**:
- **Navigation:** files or facts the seed hunted for. Fix: a doc plus an INDEX line, or a committed memory.
- **Automated checks:** a mistake a script could catch. Propose the check for the *project* repo in the report; seeds don't own project CI.
- **Standards:** a mechanical rule becomes a check (proposed as above); a judgement rule becomes a doc line.
- **Always-loaded text:** the router, the INDEX files and SEED.md against their budgets. Look for no-ops (lines that change no behaviour) and delete them.
- **Tool economy:** expensive or repeated calls, and how to avoid them.
- **Information access:** something the seed needed and could not get.
- **Routing:** a wrong seed picked (the owner redirected), or `when` lines too vague or overlapping.
- **Calls:** call chains that looped or failed; access violations, and whether the called seed's `access` is right.
- **Autonomy:** escalations that should have been decisions, and decisions the owner reversed.
- **Memory hygiene:** stale, duplicated or contradicted memories (remove the loser), and rules hiding in memory (staged as docs, then removed).
- **Sprawl:** a pending memory about a task no seed fits, seen twice, becomes a **new seed proposal**, handed to `garden/skills/garden-new-seed/SKILL.md`, which asks the owner. A seed whose folder has no commit in 60 days (`git log -1 --format=%cs -- seeds/<x>`) while others had some is proposed for retirement; overlapping seeds for merging. Past 50 seeds, propose merges rather than more groups.
- **Upstream:** if the garden has an `upstream` remote, say once in the report that `bash garden/skills/garden-sync/sync.sh status` shows whether a garden release is waiting. Never run sync from here.
- **The retro itself:** how the last retro branches fared (`memory/rejected.md`). Repeated rejections are a finding about memory, which may propose a root-tier change to `garden/skills/garden-memory/`.

## 3. Removal pass (mandatory)
Every retro removes or compacts at least one thing, or states, with the measured sizes, that everything is under 80 % of its budget.

## 4. Compaction
- **Memory folders** at 80 % of a budget or more (at 100 % writes fail): remove stale, duplicated or low-value memories with `python3 garden/skills/garden-memory/write.py remove <file>` (there is no archive: git history keeps them), and reorder INDEX.md most valuable first. A file too long for its budget is rewritten shorter by hand. Pending memories seen once and older than 60 days are removed. Check each folder with `write.py check <memory folder>`.
- **`memory/rejected.md`** at 80 %: delete its oldest lines by hand.
- **Docs and SEED.md:** compaction is a behaviour change: stage it.

## 5. Output
1. Memory changes: make them now, through write.py (or by hand for compaction, then `check`).
2. Behaviour changes (at most 5 per branch): stage them (`garden/skills/garden-memory/stage.md`), seeds tier and root tier separately.
3. Commit memory with the message `memory: retro <seed>`, so the next retro finds this one.
4. In the report, `## Retro`: each finding with its category, evidence and what you did (staged, memory, proposed for the project, or dropped and why).
