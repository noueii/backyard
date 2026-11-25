# 0004: skills inside the garden are standard `SKILL.md` files (2026-11-23)

**Renamed by [0005](0005-backyard.md)** (backyard 4.0.0): the standard garden is now **backyard**: the router `backyard`, the folder `backyard/`, the skills `backyard-*`, the repo noueii/backyard. This record keeps the names and paths it was decided with.

Status: **accepted** (the owner's decision). Amends [0001](0001-seeds.md) §1-2 and [0002](0002-framework-folder.md). Release: garden **3.0.0** (with [0003](0003-memory-layout.md)), `seeds-format` **2.0**.

## Decision
Every skill inside a garden follows the [Agent Skills](https://agentskills.io) standard: its file is `SKILL.md`, not `ENTRY.md`. That covers garden's own skills (`garden/skills/<s>/`), the owner's shared skills (`skills/<s>/`) and seeds' bundled skills (`seeds/<name>/skills/<s>/`).

- **Where a `SKILL.md` may be:** the root (the router) and one per skill folder in those three places. Nowhere else, and never in another casing (case-insensitive filesystems make `skill.md` the same file). The validator enforces both.
- **garden's own skills are prefixed:** `garden-memory`, `garden-escalate`, `garden-handoff`, `garden-sync`, `garden-new-seed`, with `name` equal to the folder. Their descriptions start with "Part of the garden skill, used through its router and seeds, never on its own." `garden` and `garden-*` are reserved: the owner's and seeds' skills never take them. The bare names garden gave up are free for the owner's own skills.
- **Read by path, as before:** the router and seeds read a skill's `SKILL.md` by its path when they need it. Nothing about how a seed runs changes.
- **A vendored skill keeps its upstream `SKILL.md`** (adding `metadata.source` and `metadata.commit`), instead of being renamed and having its links rewritten.

**Why:** the owner prefers the standard. An `ENTRY.md` was garden's own convention, so a vendored skill had to be renamed and patched, and an owner's skill could not be used anywhere else as it was. A `SKILL.md` is a skill in any tool.

## What each tool now sees
Replaces "exactly one `SKILL.md` per installed folder is required" (0001 §1), which held only while internal skills were hidden. `garden/dev/prove-install.sh`, in a temp HOME against `garden/dev/fake-model.py`, with Claude Code 2.1.330, opencode 1.18.30, pi 0.80.2 and omp 18.11:

| | discovers | sends to a model |
|---|---|---|
| Claude Code | only `garden` (it reads `<dir>/<name>/SKILL.md`, one level) | `garden` and its description; no nested skill |
| pi | only `garden` (it stops at the first folder with a `SKILL.md`) | the same |
| omp | only `garden` (one level) | the same |
| opencode | `garden` and every nested skill: garden's five `garden-*`, and with seeds their bundled skills (`plan-format`, `tdd` in the fixture) | all of them, each garden skill with its "Part of the garden skill" description |

A `SKILL.md` outside a skill folder (forbidden) is still ignored by Claude Code, pi and omp and registered by opencode.

**opencode lists the nested skills, and that is accepted** (the owner's decision): no opencode-specific mitigation or configuration. The prefix keeps garden's five from clashing with other installed skills (a `sync` or `memory` skill elsewhere is likely), and the description tells the model each one is used through the garden. The owner's own and bundled skills are listed under their own names; their descriptions should say the same, and new-seed's vendoring guide says to avoid clashes.

**Not adopted:** keeping `ENTRY.md` (the owner prefers the standard); unprefixed names (clashes in opencode, which keeps one skill per name); `disable-model-invocation` on nested skills (Claude Code only, and Claude Code doesn't list them anyway; the spec still forbids the key).

## Validator
- `SKILL.md` only at the root and as a skill folder's own file, in that casing; a leftover `ENTRY.md` in a skill folder is an error (MIGRATING).
- A skill's frontmatter: the Agent Skills fields only (an error for garden's skills, a warning for the owner's and vendored ones); `name` equals the folder.
- garden's skills are exactly the five `garden-*`; each description starts with "Part of the garden skill". A 2.x folder (`garden/skills/sync/`) or a seed listing a 2.x name (`escalate`) says what it was renamed to.
- No owner or bundled skill named `garden` or `garden-*`.
Each has a fixture in `garden/dev/fixtures/`.

## Versions
Part of garden **3.0.0**: garden's skill paths and names are an interface (seeds list `garden-escalate`; the owner's text names `garden/skills/garden-memory/write.py`), and the owner's own skill files change name, so it is a major release of both `version` and `seeds-format`. `garden/docs/MIGRATING.md` covers it with 0003. The frozen root `AGENTS.md` placeholder changes once, for the new paths and the new `SKILL.md` rule.
