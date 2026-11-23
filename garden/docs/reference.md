# Reference

Every kind of file in a garden, in a line or two. The exact format is in [spec/SPEC.md](../spec/SPEC.md).

## Yours
| File | What it is | Who changes it |
|---|---|---|
| `seeds/<name>/SEED.md` | a seed: frontmatter (`name`, `when`, `group`, `skills`, `calls`, `access`, `autonomy`) and the bot's purpose in plain prose | `new-seed`, `rsi` (staged) |
| `seeds/<name>/workflow.md` | optional, free-form: the order of work in your words; names called seeds as `seed:<name>` | `new-seed`, `rsi` (staged) |
| `seeds/<name>/skills/<s>/ENTRY.md` | a skill only this seed uses, or a vendored copy | `new-seed`, `rsi` (staged) |
| `seeds/INDEX.md` | one line per seed, `- <name>: <when>`: what the router reads | with SEED.md, in the same change |
| `docs/INDEX.md`, `docs/*.md` | your rules for every seed; each doc listed once with "read when" | `new-seed`, `rsi` (staged) |
| `seeds/<name>/docs/` | the seed's own docs; they override the root's | `new-seed`, `rsi` (staged) |
| `MEMORY.md` (root, per seed) | facts, most valuable first; reached only through the promotion gate | `memory` via `write.py` |
| `memory/lessons.md` (root, per seed) | candidate facts with the runs that saw them | `memory` via `write.py` |
| `memory/<topic>.md` | longer notes, linked from a memory or lessons line | `memory` via `write.py` |
| `seeds/<name>/memory/runs.md` | one line per run, and retro lines | `rsi` via `write.py` |
| `memory/unrouted.md` | one-off tasks no seed fit: evidence for new seeds | the router via `write.py` |
| `memory/rejected.md` | proposals you declined; rsi reads it first | `rsi`, `sync` via `write.py` |
| `memory/archive.md` | retired memory lines | `memory`, `rsi` |

Memory is written directly and committed locally. Everything else changes on a local `garden/*` branch, which you merge (or open as a PR with `sync`).

## Upstream's (`spec/upstream-paths.txt`)
| File | What it is |
|---|---|
| `SKILL.md` | the router: the only skill your tools see |
| `skills/memory/` | reading and writing memory; `write.py` is the gate for every write (mandatory) |
| `skills/rsi/` | run lines, retros, staging (mandatory) |
| `skills/escalate/` | when and how to ask you; `block.sh` builds the question block |
| `skills/handoff/` | calling or passing to another seed; `call.sh` enforces `access`, `check.sh` is the backstop |
| `skills/sync/` | pull, push memory, open PRs, take upstream releases; only when asked |
| `skills/new-seed/` | the interview that builds or changes seeds |
| `spec/`, `check/` | the format, the validator, the optional pre-commit script |
| `guide/`, `README.md`, `AGENTS.md`, `CLAUDE.md` | for people, and for agents working in the garden |
| `dev/` | maintainer files (decisions, fixtures, proofs), inert in your copy |
| `.github/workflows/garden.yml`, `.gitattributes` | CI, and the union merge for memory files |

Changes to these come from upstream releases (through `sync`), or from your own root-tier changes, which `rsi` stages separately.

## Access levels
| `access` | The seed, when another seed calls it |
|---|---|
| `read-only` | reads and searches only: no edits, no shell |
| `edit` | also edits and writes files: no shell |
| `full` (default) | everything your tool's settings allow |

Enforced by your tool through `skills/handoff/call.sh`; details per tool in `skills/handoff/access.md`.
