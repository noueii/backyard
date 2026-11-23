# The retro

Adapted from mattpocock's `retro`. Read first: this seed's `runs.md` since the last retro, `memory/unrouted.md`, `memory/rejected.md` (never re-propose a line there without new evidence), the lessons files, the conversation's escalations and owner corrections, the root and seed MEMORY.md, and the sizes of everything always loaded (the router, `docs/INDEX.md`, `seeds/INDEX.md`, both MEMORY.md, this SEED.md). Read the existing docs before proposing a rule, so a finding is "the existing rule is unclear" rather than a duplicate.

Each finding names its **evidence** (quoted run lines, unrouted lines, or an owner quote) and its **category**:

## Categories
- **Navigation:** files or facts the seed hunted for. Fix: a doc plus an INDEX line, or a memory pointer.
- **Automated checks:** a mistake a script could catch. Propose the check for the *project* repo in the report; seeds don't own project CI.
- **Standards:** a mechanical rule becomes a check (proposed as above); a judgement rule becomes a doc line.
- **Always-loaded text:** the router, the INDEX files, MEMORY.md and SEED.md against their budgets. Look for no-ops (lines that change no behaviour) and delete them.
- **Tool economy:** expensive or repeated calls, and how to avoid them.
- **Information access:** something the seed needed and could not get.
- **Routing:** a wrong seed picked (the owner redirected), or `when` lines too vague or overlapping.
- **Calls:** call chains that looped, failed or were always skipped; access violations (`viol`), and whether the called seed's `access` is right.
- **Autonomy:** escalations that should have been decisions, and decisions the owner reversed.
- **Memory hygiene:** stale, duplicated or contradicted facts, and rules hiding in memory (they move to docs).
- **Sprawl:** repeated `unrouted.md` lines become a **new seed proposal**, handed to `skills/new-seed/ENTRY.md`, which asks the owner. Seeds unused for 30 runs of their siblings, or 60 days, are proposed for retirement; overlapping seeds for merging. Past 50 seeds, propose merges rather than more groups.
- **Upstream:** if the garden has an `upstream` remote, say once in the report that `bash skills/sync/sync.sh status` shows whether a garden release is waiting. Never run sync from here.
- **Lessons:** a lesson seen in 2 runs is promoted (`skills/memory/ENTRY.md`); one not seen again since the last two retros is dropped. A lesson that is really a rule becomes a doc change, staged.
- **rsi itself:** how the last retro branches fared (`memory/rejected.md`). Repeated rejections are a finding about rsi, which may propose a root-tier change to `skills/rsi/`.

## Removal pass (mandatory)
Every retro proposes at least one deletion or compaction, or states, with the measured sizes, that everything is under 80 % of its budget.

## Compaction
- **Memory files** at 80 % of their budget or more (write.py says "compaction due"; at 100 % it refuses writes): merge duplicates, move details into topic files, move stale or low-value lines to `memory/archive.md` (`~~old line~~ · moved YYYY-MM-DD`), and reorder MEMORY.md most valuable first. Written directly: it is memory. Check with `python3 skills/memory/write.py check <file>`.
- **runs.md and unrouted.md:** keep the lines since the last two retro lines; delete older ones (git history keeps them, and the retro lines summarise them). **archive.md** and **rejected.md** at 80 %: delete their oldest lines. Written directly.
- **Docs and SEED.md:** compaction is a behaviour change: stage it.

## Output
1. Memory changes: write them now.
2. Behaviour changes (at most 5): stage them (`skills/rsi/stage.md`), seeds tier and root tier separately.
3. In the report, `## Retro`: each finding with its category, evidence and what you did (staged, memory, proposed for the project, or dropped and why).
