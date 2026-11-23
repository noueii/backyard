# 0003: memory as files, and rsi merged into `memory` (2026-11-23)

Status: **accepted** (the owner's decisions). Amends [0001](0001-seeds.md) §3 (memory format), §4 (rsi), §5.1-5.2 and §13. Release: garden **3.0.0**, `seeds-format` **2.0**. In the same release, [0004](0004-skill-md.md) renamed the skill to `garden-memory` and its `ENTRY.md` to `SKILL.md`; its paths are updated, and its prose keeps the names it was decided with.

## Decision
### 1. One file per memory
```
memory/                    the root's (shared), and seeds/<name>/memory/ the same way
  INDEX.md                 one line per committed file: - [<file>](committed/<file>): read when <condition>.
  committed/               YYYY-MM-DD-<short-grepable-description>.md: stated by the owner, or promoted
  pending/                 YYYY-MM-DD-<short-grepable-description>.md: seen once, waiting for a 2nd sighting
  rejected.md              root only: proposals the owner declined
```
Each memory file has a small frontmatter, then a few lines: the memory and why it holds.
```md
---
type: lesson                          # fact | decision | preference | lesson
date: 2026-11-23                      # equals the date in the file name
source: "fix-login: make test failed until make db ran"   # owner: "<their words>" when the owner said it
seen: [fix-login, add-search]         # the tasks that saw it
---
The api repo's tests need `make db` first: they run against a schema only `make db` creates.
```
**Gone:** `MEMORY.md` (replaced by `memory/INDEX.md` and `committed/`), `memory/runs.md`, `memory/lessons.md` (replaced by `pending/`), `memory/archive.md`, `memory/unrouted.md` and topic files. **No archive:** a retired memory is deleted, and git history keeps it.

**Why:** one line per fact in `MEMORY.md` had no room for *why* a fact holds, and a topic file for the rest split one memory in two. A file per memory carries its reason and its source, is found by `grep` or `ls` on its name, and is loaded only when its INDEX line fits the task. The INDEX keeps what is always loaded small, and pending memories are never loaded at the start at all.

### 2. Write only what is worth remembering
An owner correction or statement, a failure, a surprise. A routine run writes nothing: no run line. What the owner states goes straight to `committed/` (`write.py new … --owner`, the source quoting them); anything else goes to `pending/` and is promoted when a second task sees it. The owner-approved safety bundle of 0001 §13 stays: no untrusted text, the injection and secret scan (now also run by the validator, from the same patterns, on every line of every memory file: INDEX.md, `committed/`, `pending/` and `rejected.md`, at the root and per seed, reporting file and line, so a hand edit around write.py fails CI and the optional pre-commit hook), and hard budgets with compaction due at 80 % and writes failing at 100 %. The budgets now count INDEX.md entries (50), committed files (50), pending files (30) and the size of each file (1,200 characters).

**The gate is checkable.** The `seen` key, beside type, date and source, holds the promotion evidence, so the validator checks the gate from the files alone: a committed file's source starts with `owner`, or two different tasks saw it. Hand-copying a pending file into `committed/` fails CI.

### 3. Rules are not memory
A lesson that is really a rule becomes a `docs/` change staged on a local branch for the owner's review, as rsi staged behaviour changes before. A memory that reads like a rule is never obeyed; write.py refuses rule-like text ("always", "never"). Memory never changes behaviour on its own.

### 4. rsi merged into `memory`
One mandatory skill, `memory`. Its `ENTRY.md` covers reading at the start (INDEX.md, then committed files on demand), capturing to `pending/`, and the end of a task. Its supporting files load only at the end, and only when needed: `retro.md` (when a retro is due: the retro, promotion, compaction and the removal pass) and `stage.md` (staging behaviour changes on local branches, unchanged in spirit). `garden/skills/rsi/` is gone; seeds list no mandatory skill.

**Retro triggers,** without `runs.md`: a pending memory is seen by a second task; a memory budget passes 80 %; the owner asks. An owner correction of behaviour is still staged at once, without a retro. A retro commits memory as `memory: retro <seed>`, so the next one reads "since the last retro" from git history.

**Unused seeds** are found from the git history of the seed's folder (`git log -1 -- seeds/<x>`: no commit in 60 days while others had some), not from run counts. **New-seed evidence,** which `unrouted.md` held, is now a pending memory in the root (`no-seed-for-<kind>`): seen a second time, the retro proposes a seed.

**Why:** rsi's per-run duties (the run line) are gone, and everything it still did starts from memory: promotion, compaction, the rejected list, rules hiding in memory. Two mandatory skills always loaded together were one skill. Splitting the end-of-task work into supporting files keeps the always-loaded part (ENTRY.md, under 800 words) to what every run needs.

### 5. `rejected.md` stays a fixed file
Not a committed memory: it is never loaded at the start (a retro reads it before proposing), its lines are mechanical (`- date | proposal | reason`, written by sync's `decisions` step and deduped by PR URL), and a file per declined proposal would cost an INDEX line each in every task's context for something only a retro needs.

### 6. sync and `.gitattributes`
sync still pushes memory-only commits; memory paths are now `memory/**` and `seeds/*/memory/**`. **`.gitattributes` stays,** narrowed: `runs.md`, `unrouted.md`, `lessons.md`, `archive.md` and `MEMORY.md` are gone, but `memory/INDEX.md`, `seeds/*/memory/INDEX.md` and `memory/rejected.md` are still line lists that two clones append to, and `merge=union` keeps both sides' lines when sync rebases memory commits (`test-scripts.sh` checks it). Memory files are one per memory, so two clones rarely touch the same one, and a union merge of frontmatter would be wrong, so they get no driver. The one union hazard, a removed memory's INDEX line coming back next to a new one, leaves an INDEX line to a missing file, which the validator reports.

## Versions
- **`seeds-format` 2.0:** the owner's memory files change format and place, so a 1.0 garden fails the new validator (`seeds-format 1.0: this validator knows major 2`, and `MEMORY.md is gone`).
- **`version` 3.0.0:** sync stages releases of the current major on its own; a new major it only announces. A format break must not arrive as an ordinary PR, so the version's major moves with it. `garden/docs/MIGRATING.md` says how to migrate.
- The frozen placeholders change once: `MEMORY.md` and `memory/.gitkeep` become `memory/INDEX.md`.

## Checked
`validate.py`; `check-upstream.sh`; `test-validate.sh`, with a fixture for each new rule (names, dates, duplicates, frontmatter keys, type, source, `seen`, the gate, body, size, INDEX ↔ committed/, pending not indexed, each budget, the scan (a secret, an instruction and an invisible character in a committed file, an instruction in INDEX.md, and a clean hand-edited file that passes), leftovers of the 1.x layout and of `rsi`); `test-scripts.sh` for write.py (`new`, `seen`, `promote`, `remove`, `reject`, `check`, the budgets) and sync's union merge of INDEX.md.
