# The retro

Adapted from mattpocock's `retro`. Read first: this seed's `runs.md` since the last retro, `memory/unrouted.md`, the conversation's escalations and owner corrections, the root and seed MEMORY.md, and the sizes of everything always loaded (the router, `docs/INDEX.md`, `seeds/INDEX.md`, both MEMORY.md, this SEED.md). Read the existing docs before proposing a rule, so a finding is "the existing rule is unclear" rather than a duplicate.

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
- **Upstream:** if the root memory line about the last upstream check is over 30 days old (or missing), suggest running `sync` in the report. Never run it from here.
- **rsi itself:** how the last retro branches fared (root memory lines `rsi proposal rejected: ...`). Repeated rejections are a finding about rsi, which may propose a root-tier change to `skills/rsi/`.

## Removal pass (mandatory)
Every retro proposes at least one deletion or compaction, or states, with the measured sizes, that everything is within 75 % of budget.

## Compaction
- **MEMORY.md** over 75 % of its budget: merge duplicates, move details into topic files, move stale lines to `memory/archive.md` (`~~old line~~ · moved YYYY-MM-DD`). Written directly: it is memory.
- **runs.md and unrouted.md:** keep the lines since the last two retro lines; delete older ones (git history keeps them, and the retro lines summarise them). Written directly.
- **Docs and SEED.md:** compaction is a behaviour change: stage it.

## Output
1. Memory changes: write them now.
2. Behaviour changes (at most 5): stage them (`skills/rsi/stage.md`), seeds tier and root tier separately.
3. In the report, `## Retro`: each finding with its category, evidence and what you did (staged, memory, proposed for the project, or dropped and why).
