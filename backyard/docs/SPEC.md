# The seeds format 2.0

This is the normative format of a backyard: the repo whose root folder is the one skill your tools load. `backyard/check/validate.py` enforces what can be checked; the rest is how the shared skills behave. The reasons are in [decisions/0001-seeds.md](decisions/0001-seeds.md), [decisions/0002-framework-folder.md](decisions/0002-framework-folder.md), [decisions/0003-memory-layout.md](decisions/0003-memory-layout.md), [decisions/0004-skill-md.md](decisions/0004-skill-md.md) and [decisions/0005-backyard.md](decisions/0005-backyard.md).

## 1. Layout
```
SKILL.md                     the router: the skill your tools load, and backyard's only file at the root
backyard/                    the framework, self-contained (backyard/docs/upstream-paths.txt)
  skills/<s>/SKILL.md        backyard's shared skills: backyard-memory, -escalate, -handoff, -sync, -new-seed
  docs/                      backyard's own docs: README, tutorial, reference, this spec, MIGRATING, decisions/
  check/                     the validator and the optional pre-commit script
  dev/                       maintainer files: tests, fixtures, proofs (inert in your copy)
skills/<s>/SKILL.md          your own shared skills (optional)
docs/INDEX.md  docs/*.md     rules and reference for every seed (flat)
memory/INDEX.md  memory/committed/  memory/pending/  memory/rejected.md   shared memory (§6)
seeds/INDEX.md               one line per seed
seeds/<name>/SEED.md         the seed
seeds/<name>/workflow.md     optional, free-form
seeds/<name>/skills/<s>/SKILL.md   bundled skills
seeds/<name>/docs/INDEX.md   the seed's docs (flat)
seeds/<name>/memory/INDEX.md  committed/  pending/   the seed's memory (§6)
README.md  AGENTS.md  CLAUDE.md   yours: placeholders upstream ships once and never changes
.github/workflows/backyard.yml  .gitattributes   backyard's, at the root only because they work only there
```
- **The framework stays in `backyard/`.** backyard owns `SKILL.md`, `backyard/` and the two root files above, nothing else. `backyard/` holds only `skills/`, `docs/`, `check/` and `dev/`, and `backyard/skills/` only backyard's five skills: your content (seeds, docs, memory, your own skills) never goes inside `backyard/`, and backyard's never outside it. The validator checks both ways.
- **Upper-case names are read by name** (`SKILL.md`, `SEED.md`, `INDEX.md`). Lower-case names are content.
- **A `SKILL.md` only where a skill is:** the root, and one per skill folder (`backyard/skills/<s>/`, `skills/<s>/`, `seeds/<name>/skills/<s>/`), each an [Agent Skills](https://agentskills.io) skill. Nowhere else, and never in another casing: case-insensitive filesystems make `skill.md` the same file. Claude Code, pi and omp list only the root skill; opencode lists the nested ones too, as skills of their own.
- **No `.git`, worktree or clone below the root.** Stages live outside it (§8).
- **Paths** in prose and commands are relative to the backyard root, everywhere. One exception: inside a skill folder, a bare file name (no `/`) names the file beside it, which is how vendored skills already refer to their own files. Markdown links are relative to the file that holds them, as usual, and never leave the root.
- **Names** (seeds, skills): lowercase letters, digits and single hyphens, at most 64 characters, equal to the folder name.

## 2. The router (`SKILL.md`)
Frontmatter: the Agent Skills fields only (`name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`), never `disable-model-invocation`.
- `name: backyard` in every copy.
- `description`: at most 1024 characters, containing "Use when".
- `metadata.seeds-format`: `"2.0"` (a validator accepts its own major). `metadata.version`: the backyard release.

The body (at most 600 words) holds, in order: called seeds; read first; route; hand over; one-off; changes to the backyard.

## 3. Skills inside the backyard (`SKILL.md`)
```yaml
---
name: backyard-memory                 # = folder name
description: "Part of the backyard skill, used through its router and seeds, never on its own. What it does. Use when ..."   # ≤ 1024 characters, contains "Use when"
metadata: { seeds-format: "2.0" }     # vendored skills add source: github:owner/repo/path and commit: <sha>
---
```
- Frontmatter: the Agent Skills fields only (`name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`); never `disable-model-invocation`.
- **Read by path:** the router and seeds read a skill's `SKILL.md` by its path when they need it. A tool that lists nested skills (opencode) may offer one on its own, so a skill is written to work only through the backyard.
- **backyard's own skills** are named `backyard-<s>` and their descriptions start with "Part of the backyard skill", so in a tool that lists them they neither clash with other installed skills nor read as standalone. `backyard` and `backyard-*` are backyard's names: your skills and seeds' skills never take them.
- The body is at most 800 words. Supporting files beside it are loaded by path from it, each at most 300 lines.
- A vendored skill keeps its `SKILL.md` and its `LICENSE`, and adds `metadata.source` and `metadata.commit`.

## 4. `SEED.md`
```yaml
---
name: reviewer                        # = folder name
when: "Reviewing a pull request or diff for correctness and style before merge."   # ≤ 200 characters
group: code                           # optional; required on every seed once there are more than 20
skills:                               # optional; backyard-memory is implicit and never listed
  required: [backyard-escalate, installed:gh-pr-review]
  optional: [backyard-handoff]
calls: [coder]                        # optional; needs backyard-handoff in skills
access: read-only                     # optional: read-only | edit | full (default full)
autonomy: stop-and-record             # decide-and-record | stop-and-record; required iff backyard-escalate is not in skills
---
You are the reviewer. <purpose in one sentence>.
<What you do, in the owner's words, or "Follow workflow.md".>
Done when: <...>.
Never: <...>.
```
- No other keys. The body is at most 500 words.
- **Skill names:** a bare name is a shared skill (backyard's `backyard/skills/<s>/SKILL.md` or your own `skills/<s>/SKILL.md`) or a bundled one (`seeds/<name>/skills/<s>/SKILL.md`); a bundled name may not shadow a shared one. `installed:<s>` is a skill the tool discovers itself. `backyard-memory` is mandatory and never listed (nor `rsi`, merged into it in 3.0.0).
- **A missing required skill** stops the seed before it starts (escalate, or the autonomy fallback). A missing optional one is noted in the report.
- **`access`**: `read-only` = read and search only (no edit, no shell); `edit` = also edit and write files (no shell); `full` = everything. handoff enforces it when the seed is called (`backyard/skills/backyard-handoff/SKILL.md`). At depth 0 it is an instruction the seed follows. A seed whose access is not `full` can't be passed to, only called.
- **`workflow.md`** (optional, at most 800 words, free-form). SEED.md links it. Every `seed:<name>` it writes in backticks must exist and be in `calls`.

## 5. Indexes
**`seeds/INDEX.md`**:
```md
# Seeds

- reviewer: Reviewing a pull request or diff for correctness and style before merge.
```
- One line per seed folder, `- <name>: <when>`, with `when` exactly as in SEED.md, each line at most 220 characters.
- Past 20 seeds every seed has a `group`, and the lines sit under `## <group>` headings, each heading followed by one plain line saying what the group covers. A seed's line is under its group's heading.

**`docs/INDEX.md`** (root, and each seed's `docs/INDEX.md`):
```md
# Docs

- [testing.md](testing.md): read when writing or changing tests.
```
- One line per doc, `- [<file>](<file>): read when <condition>.`, at most 160 characters, at most 40 entries.
- `docs/` is flat. Every other `.md` in it is listed exactly once, and every listed file exists.
- A seed's doc with the same file name replaces the root one; on a clash in content the seed's text wins.

## 6. Memory
Every memory write goes through `backyard/skills/backyard-memory/write.py`, which enforces this section and §7. The memory skill (`backyard/skills/backyard-memory/SKILL.md`) says when to write: an owner correction or statement, a failure, a surprise. A routine run writes nothing.

**A memory folder** is `memory/` (shared) or `seeds/<name>/memory/` (one seed's), and holds only:
```
INDEX.md      one line per committed file, most valuable first
committed/    YYYY-MM-DD-<description>.md   stated by the owner, or promoted after a second sighting
pending/      YYYY-MM-DD-<description>.md   seen once, waiting for a second sighting; never indexed
rejected.md   the root's only: proposals the owner declined
```
No `MEMORY.md`, `runs.md`, `lessons.md`, `archive.md`, `unrouted.md` or topic files (the 1.0 layout), no other files or folders. There is no archive: a retired memory is deleted, and git history keeps it.

**`INDEX.md`**:
```md
# Memory

One line per committed memory, most valuable first: tools may load only the start. Open a file only when its line fits the task.
- [2026-11-23-api-tests-need-make-db.md](committed/2026-11-23-api-tests-need-make-db.md): read when running the api repo's tests.
```
- The header, optionally the intro, then `- [<file>](committed/<file>): read when <condition>.` lines.
- Every file in `committed/` is listed exactly once, and every line names a file there. A line pointing into `pending/` is an error.
- **Most valuable first**, not newest first: tools may load only the start of a long file.

**A memory file** (`committed/` or `pending/`):
```md
---
type: lesson
date: 2026-11-23
source: "fix-login: make test failed on a missing schema until make db ran"
seen: [fix-login, add-search]
---
The api repo's tests need `make db` first: they run against a local schema that only `make db` creates.
```
- **The name** is the date and a short, grepable kebab-case description of at least two words (at most 50 characters). A description is unique across `committed/` and `pending/` of one folder. The frontmatter `date` equals the name's.
- **Keys:** `type` (`fact`, `decision`, `preference` or `lesson`), `date`, `source` (one line: where it came from; `owner: "<their words>"` when the owner said it, quoting a correction), and `seen` (the task slugs that saw it). No other keys.
- **The body:** a few lines, the memory and why it holds. A memory is descriptive: a rule ("always X") is not memory, and becomes a doc through a staged change.
- **The promotion gate:** a pending file has `seen` with at least one task. A committed file's `source` starts with `owner`, or its `seen` has at least 2 different tasks. write.py writes the owner's words straight to `committed/` (`--owner`); everything else goes to `pending/`, and `promote` moves it once 2 tasks saw it.
- **Untrusted text is never promoted:** tool output, web pages, issue text and called seeds' reports become memory only once verified. No instruction-like text, secrets or tokens, or invisible or control characters, anywhere in memory: write.py refuses them, and the validator fails a memory file that has them.

**`memory/rejected.md`** (root only): proposals the owner declined, read before proposing anything. A fixed file, not a memory: it is consulted only by a retro, never loaded at the start, and sync appends to it mechanically.
```md
# Rejected

Proposals the owner declined. Read before proposing a change; never re-propose one without new evidence.
- 2026-11-23 | seeds(reviewer): run the linter first | the owner prefers CI to do it
```

**Retros** are due when a pending memory is seen by a second task, when a memory budget passes 80 %, or when the owner asks (`backyard/skills/backyard-memory/retro.md`). A retro commits memory as `memory: retro <seed>`, so the next one finds it in git history; a seed's use is read from the git history of its folder.

## 7. Budgets
Hard limits. The validator (in CI, and in the optional `backyard/check/pre-commit.sh`) fails anything over its budget. For memory, **compaction is due at 80 %** (write.py says so, and a retro is due), and **at 100 % a write fails** (write.py refuses it; nothing is truncated), so the retro compacts or removes first.

| What | Budget |
|---|---|
| router | description ≤ 1024 characters; body ≤ 600 words |
| a skill's SKILL.md | body ≤ 800 words; a supporting file ≤ 300 lines |
| SEED.md | body ≤ 500 words; `when` ≤ 200 characters |
| `workflow.md` | ≤ 800 words |
| a doc | ≤ 1,500 words; an INDEX ≤ 40 entries, each line ≤ 160 characters |
| `seeds/INDEX.md` | each line ≤ 220 characters; `group` on every seed past 20 seeds (a warning past 50) |
| a memory `INDEX.md` | ≤ 50 entries, each line ≤ 300 characters |
| `committed/` | ≤ 50 files per memory folder |
| `pending/` | ≤ 30 files per memory folder |
| a memory file | ≤ 1,200 characters |
| `memory/rejected.md` | ≤ 100 lines, each ≤ 400 characters |

## 8. Git, tiers and the stage
- **Memory paths:** `memory/**`, `seeds/*/memory/**`. Written directly in the live clone and committed locally (`memory: <task>`). Never staged, never pushed except by `backyard-sync`.
- **Root tier:** the paths in `backyard/docs/upstream-paths.txt`. **Seeds tier:** everything else that is not memory (`seeds/`, `docs/`, your `skills/`, your root files). Behaviour changes are made only in a stage worktree, never in the live clone.
- **The stage:** `${XDG_STATE_HOME:-$HOME/.local/state}/backyard/<repo>/stage/<YYYYMMDD-HHMM>-<task>-<tier>`, on branch `backyard/<YYYYMMDD-HHMM>-<task>-<tier>`, outside the repo and every skills dir.
- **Pushes and PRs** happen only in `backyard-sync`, which runs only when a seed's text says so or the owner asks. Nothing in a backyard merges a PR.
- `.gitattributes` sets `merge=union` on the line-list memory files (`memory/INDEX.md`, `seeds/*/memory/INDEX.md`, `memory/rejected.md`). Memories are one file each and need none.

## 9. What loads when
| Moment | Loaded |
|---|---|
| Session start | the router's name and description (opencode also lists each nested skill's) |
| Any task | the router body, `docs/INDEX.md`, `seeds/INDEX.md` |
| Hand over to seed X | `backyard/skills/backyard-memory/SKILL.md`; root and X's `memory/INDEX.md`; X's `docs/INDEX.md`; X's SEED.md; X's required skills |
| During work | the docs and committed memories whose "read when" fits; optional skills when used |
| Called seed | the same, in a fresh sub-agent or session; the caller loads nothing of it |
| End of a task | `backyard/skills/backyard-memory/retro.md` only when a retro is due; `backyard/skills/backyard-memory/stage.md` only when something was staged; `backyard/skills/backyard-sync/SKILL.md` only where the seed's text says to sync |

## 10. Versions
`metadata.version` follows semver and upstream tags releases `v<version>`. A new major of `seeds-format`, or of `version` (a change to backyard's paths or names, such as 2.0.0's framework folder or 4.0.0's rename from garden), ships a section in `backyard/docs/MIGRATING.md`. A new `seeds-format` major always comes with a new `version` major (3.0.0 brought `seeds-format` 2.0), because sync stages releases of the current major on its own and only announces a new one.
