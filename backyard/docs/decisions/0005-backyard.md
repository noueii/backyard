# 0005: the standard is named backyard (2026-11-25)

Status: **accepted** (the owner's decision). Renames what [0001](0001-seeds.md), [0002](0002-framework-folder.md), [0003](0003-memory-layout.md) and [0004](0004-skill-md.md) call garden. Release: backyard **4.0.0**; `seeds-format` stays **2.0**.

## Decision
The standard, its repo and everything named after it are **backyard**. The owner renamed the repo noueii/garden to noueii/backyard; the name garden is kept for the owner's own, separate config repo.

| Was | Now |
|---|---|
| the router skill `garden` (`name: garden`) | `backyard` (`name: backyard`) |
| the framework folder `garden/` | `backyard/` |
| the skills `garden-memory`, `-escalate`, `-handoff`, `-sync`, `-new-seed` | `backyard-memory`, `-escalate`, `-handoff`, `-sync`, `-new-seed` |
| reserved names `garden`, `garden-*` | `backyard`, `backyard-*` (garden and garden-* are free) |
| `.github/workflows/garden.yml` | `.github/workflows/backyard.yml` |
| staged branches `garden/*`, state in `~/.local/state/garden/` | `backyard/*`, `~/.local/state/backyard/` |
| `GARDEN_DRY`, `GARDEN_NO_GH`; opencode's `garden-<level>` handoff agent | `BACKYARD_DRY`, `BACKYARD_NO_GH`; `backyard-<level>` |
| a user's repo, "a garden" | "a backyard" |

Nothing else changes: the layout, the seeds format, memory and how a seed runs are as before.

## Records
0001-0004 keep the names and paths they were decided with, under a note pointing here, so they read as they were accepted. The rest of the docs, the validator, the scripts and the fixtures use the new names.

## Versions
**4.0.0**, a new major of `version`: the router's name, the framework's paths and its skill names are an interface (seeds list `backyard-escalate`, the owner's text names `backyard/skills/backyard-memory/write.py`, CI names the workflow), and SPEC §10 makes a change to them a major release. sync takes releases of the current major only, so a 3.x backyard gets a printed notice and takes it by hand (`backyard/docs/MIGRATING.md`).

`seeds-format` stays **2.0**: the format of seeds, docs and memory is unchanged; only the names of backyard's skills they refer to change, as 2.0.0's paths did under `seeds-format` 1.0. The frozen root `README.md` and `AGENTS.md` placeholders change once, because they name the router and the moved paths; a user's own copies are theirs, and MIGRATING says what to update.
