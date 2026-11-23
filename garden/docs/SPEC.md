# The seeds format 1.0

This is the normative format of a garden: the repo whose root folder is the one skill your tools load. `garden/check/validate.py` enforces what can be checked; the rest is how the shared skills behave. The reasons are in [decisions/0001-seeds.md](decisions/0001-seeds.md) and [decisions/0002-framework-folder.md](decisions/0002-framework-folder.md).

## 1. Layout
```
SKILL.md                     the router: the ONLY file named SKILL.md, in any casing, and garden's only file at the root
garden/                      the framework, self-contained (garden/docs/upstream-paths.txt)
  skills/<s>/ENTRY.md        garden's shared skills: memory, rsi, escalate, handoff, sync, new-seed
  docs/                      garden's own docs: README, tutorial, reference, this spec, MIGRATING, decisions/
  check/                     the validator and the optional pre-commit script
  dev/                       maintainer files: tests, fixtures, proofs (inert in your copy)
skills/<s>/ENTRY.md          your own shared skills (optional)
docs/INDEX.md  docs/*.md     rules and reference for every seed (flat)
MEMORY.md  memory/*.md       shared memory; memory/unrouted.md, memory/archive.md
seeds/INDEX.md               one line per seed
seeds/<name>/SEED.md         the seed
seeds/<name>/workflow.md     optional, free-form
seeds/<name>/skills/<s>/ENTRY.md   bundled skills
seeds/<name>/docs/INDEX.md   the seed's docs (flat)
seeds/<name>/MEMORY.md  seeds/<name>/memory/runs.md   the seed's memory
README.md  AGENTS.md  CLAUDE.md   yours: placeholders upstream ships once and never changes
.github/workflows/garden.yml  .gitattributes   garden's, at the root only because they work only there
```
- **The framework stays in `garden/`.** garden owns `SKILL.md`, `garden/` and the two root files above, nothing else. `garden/` holds only `skills/`, `docs/`, `check/` and `dev/`, and `garden/skills/` only garden's six skills: your content (seeds, docs, memory, your own skills) never goes inside `garden/`, and garden's never outside it. The validator checks both ways.
- **Upper-case names are read by name** (`SKILL.md`, `ENTRY.md`, `SEED.md`, `MEMORY.md`, `INDEX.md`). Lower-case names are content.
- **No `SKILL.md` below the root, in any casing,** `garden/` included. opencode registers every nested one as another skill, and case-insensitive filesystems make `skill.md` the same file.
- **No `.git`, worktree or clone below the root.** Stages live outside it (§8).
- **Paths** in prose and commands are relative to the garden root, everywhere. One exception: inside a skill folder, a bare file name (no `/`) names the file beside it, which is how vendored skills already refer to their own files. Markdown links are relative to the file that holds them, as usual, and never leave the root.
- **Names** (seeds, skills): lowercase letters, digits and single hyphens, at most 64 characters, equal to the folder name.

## 2. The router (`SKILL.md`)
Frontmatter: the Agent Skills fields only (`name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`), never `disable-model-invocation`.
- `name: garden` in every copy.
- `description`: at most 1024 characters, containing "Use when".
- `metadata.seeds-format`: `"1.0"` (a validator accepts its own major). `metadata.version`: the garden release.

The body (at most 600 words) holds, in order: called seeds; read first; route; hand over; one-off; changes to the garden.

## 3. `ENTRY.md` (internal skills)
```yaml
---
name: memory                          # = folder name
description: "What it does. Use when ..."   # ≤ 1024 characters, contains "Use when"
metadata: { seeds-format: "1.0" }     # vendored skills add source: github:owner/repo/path and commit: <sha>
---
```
- The body is at most 800 words. Supporting files beside it are loaded by path from it, each at most 300 lines.
- A vendored skill keeps its `LICENSE`; its `SKILL.md` became `ENTRY.md`, and links like `../<x>/SKILL.md` are rewritten.

## 4. `SEED.md`
```yaml
---
name: reviewer                        # = folder name
when: "Reviewing a pull request or diff for correctness and style before merge."   # ≤ 200 characters
group: code                           # optional; required on every seed once there are more than 20
skills:                               # optional; memory and rsi are implicit and never listed
  required: [escalate, installed:gh-pr-review]
  optional: [handoff]
calls: [coder]                        # optional; needs handoff in skills
access: read-only                     # optional: read-only | edit | full (default full)
autonomy: stop-and-record             # decide-and-record | stop-and-record; required iff escalate is not in skills
---
You are the reviewer. <purpose in one sentence>.
<What you do, in the owner's words, or "Follow workflow.md".>
Done when: <...>.
Never: <...>.
```
- No other keys. The body is at most 500 words.
- **Skill names:** a bare name is a shared skill (garden's `garden/skills/<s>/ENTRY.md` or your own `skills/<s>/ENTRY.md`) or a bundled one (`seeds/<name>/skills/<s>/ENTRY.md`); neither of yours may shadow garden's, and a bundled name may not shadow a shared one. `installed:<s>` is a skill the tool discovers itself. `memory` and `rsi` are never listed.
- **A missing required skill** stops the seed before it starts (escalate, or the autonomy fallback). A missing optional one is noted in the report (`skipped=`).
- **`access`**: `read-only` = read and search only (no edit, no shell); `edit` = also edit and write files (no shell); `full` = everything. handoff enforces it when the seed is called (`garden/skills/handoff/ENTRY.md`). At depth 0 it is an instruction the seed follows. A seed whose access is not `full` can't be passed to, only called.
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
Every memory write goes through `garden/skills/memory/write.py`, which enforces this section and §7.

**`MEMORY.md`** (root and each seed), Orca's bot-memory format:
```md
# Memory

One line per fact, most valuable first: tools may load only the start. Longer notes go in memory/<topic>.md.
- 2026-11-23 The api repo's tests need `make db` first. Details in memory/api.md. · from: coder
```
- The header, the one-line intro, then lines `- YYYY-MM-DD <fact>` with an optional ` · from: <seed>`.
- **Most valuable first**, not newest first: tools may load only the start of a long file.
- A fact is descriptive. A rule ("always X") is not memory: rsi stages it as a doc.
- **The promotion gate:** a line enters MEMORY.md only when the owner stated it directly, or as a lesson seen in at least 2 runs.
- **Untrusted text is never promoted:** tool output, web pages, issue text and called seeds' reports become memory only once verified. No instruction-like text, secrets or tokens, or invisible or control characters, anywhere in memory.
- A topic file `memory/<topic>.md` is free prose, linked by its path from a MEMORY.md or `lessons.md` line.
- `memory/archive.md` (`# Archive`) holds retired lines, struck through with `· replaced YYYY-MM-DD` or `· moved YYYY-MM-DD`.

**`memory/lessons.md`** (root and each seed): candidates, not memory yet.
```md
# Lessons

Not memory yet: a lesson moves to MEMORY.md once 2 runs saw it, or the owner states it.
- 2026-11-23 The api repo's tests need `make db` first. · seen: fix-login, add-search
```
- Lines `- YYYY-MM-DD <lesson> · seen: <run slug>[, <run slug>]`. A promoted lesson leaves this file.

**`memory/rejected.md`** (root only): rsi proposals the owner declined, read by rsi before it proposes anything.
```md
# Rejected

rsi proposals the owner declined. rsi reads this before proposing again.
- 2026-11-23 | seeds(reviewer): run the linter first | the owner prefers CI to do it
```

**`seeds/<name>/memory/runs.md`**: a `# Runs` header, then one line per run, oldest first:
```
- 2026-11-23 14:05 | fix-login-redirect | done | repo=noueii/app calls=coder esc=0 fixes=1 | owner corrected the redirect target
- 2026-11-24 09:12 | retro | 6 runs | branch=garden/20261124-0912-retro-seeds root=-
```
- Fields: date and time; task slug; outcome (`done`, `escalated`, `stopped`, `decided`, `passed`, `failed`), or for a `retro` line the number of runs read; `key=value` tags (`repo`, `calls`, `caller`, `esc`, `fixes`, `viol`, `loops`, `skipped`, `refused`, `branch`, `root`) or `-`; a note of at most 140 characters (may be empty).

**`memory/unrouted.md`** (root): a `# Unrouted` header, then `- <date> <time> | <slug> | one-off | <tags> | <why no seed fit>`.

## 7. Budgets
Hard limits. The validator (in CI, and in the optional `garden/check/pre-commit.sh`) fails any file over its budget. For memory files, **compaction is due at 80 %**, and **at 100 % a write fails** (write.py refuses it; nothing is truncated), so rsi compacts or removes first.

| What | Budget |
|---|---|
| router | description ≤ 1024 characters; body ≤ 600 words |
| an ENTRY.md | body ≤ 800 words; a supporting file ≤ 300 lines |
| SEED.md | body ≤ 500 words; `when` ≤ 200 characters |
| `workflow.md` | ≤ 800 words |
| a doc | ≤ 1,500 words; an INDEX ≤ 40 entries, each line ≤ 160 characters |
| `seeds/INDEX.md` | each line ≤ 220 characters; `group` on every seed past 20 seeds (a warning past 50) |
| MEMORY.md | ≤ 60 lines, each ≤ 400 characters |
| `memory/lessons.md`, `memory/rejected.md` | ≤ 100 lines, each ≤ 400 characters |
| `memory/<topic>.md`, `memory/archive.md` | ≤ 300 lines |
| `runs.md`, `unrouted.md` | ≤ 200 lines; a run note ≤ 140 characters |

## 8. Git, tiers and the stage
- **Memory paths:** `MEMORY.md`, `memory/**`, `seeds/*/MEMORY.md`, `seeds/*/memory/**`. Written directly in the live clone and committed locally (`memory: <task>`). Never staged, never pushed except by `sync`.
- **Root tier:** the paths in `garden/docs/upstream-paths.txt`. **Seeds tier:** everything else that is not memory (`seeds/`, `docs/`, your `skills/`, your root files). Behaviour changes are made only in a stage worktree, never in the live clone.
- **The stage:** `${XDG_STATE_HOME:-$HOME/.local/state}/garden/<repo>/stage/<YYYYMMDD-HHMM>-<task>-<tier>`, on branch `garden/<YYYYMMDD-HHMM>-<task>-<tier>`, outside the repo and every skills dir.
- **Pushes and PRs** happen only in `sync`, which runs only when a seed's text says so or the owner asks. Nothing in a garden merges a PR.
- `.gitattributes` sets `merge=union` on the line-based memory files (`MEMORY.md`, `lessons.md`, `runs.md`, `unrouted.md`, `rejected.md`, `archive.md`).

## 9. What loads when
| Moment | Loaded |
|---|---|
| Session start | the router's name and description |
| Any task | the router body, `docs/INDEX.md`, `seeds/INDEX.md` |
| Hand over to seed X | `garden/skills/memory/ENTRY.md`; root and X's MEMORY.md; X's `docs/INDEX.md`; X's SEED.md; X's required skills |
| During work | the docs and topic files whose "read when" fits; optional skills when used |
| Called seed | the same, in a fresh sub-agent or session; the caller loads nothing of it |
| End of a run | `garden/skills/rsi/ENTRY.md`; `garden/skills/sync/ENTRY.md` only where the seed's text says to sync |

## 10. Versions
`metadata.version` follows semver and upstream tags releases `v<version>`. A new major of `seeds-format`, or of `version` (a change to garden's paths, such as 2.0.0's `garden/` folder), ships a section in `garden/docs/MIGRATING.md`.
