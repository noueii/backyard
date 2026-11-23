# Reference

Every kind of file in a garden, in a line or two. The exact format is in [SPEC.md](SPEC.md).

## Yours
| File | What it is | Who changes it |
|---|---|---|
| `seeds/<name>/SEED.md` | a seed: frontmatter (`name`, `when`, `group`, `skills`, `calls`, `access`, `autonomy`) and the bot's purpose in plain prose | `new-seed`, a retro (staged) |
| `seeds/<name>/workflow.md` | optional, free-form: the order of work in your words; names called seeds as `seed:<name>` | `new-seed`, a retro (staged) |
| `seeds/<name>/skills/<s>/ENTRY.md` | a skill only this seed uses, or a vendored copy | `new-seed`, a retro (staged) |
| `skills/<s>/ENTRY.md` | your own shared skill, for every seed (optional; never a garden skill's name) | `new-seed`, a retro (staged) |
| `seeds/INDEX.md` | one line per seed, `- <name>: <when>`: what the router reads | with SEED.md, in the same change |
| `docs/INDEX.md`, `docs/*.md` | your rules for every seed; each doc listed once with "read when" | `new-seed`, a retro or your correction (staged) |
| `seeds/<name>/docs/` | the seed's own docs; they override the root's | `new-seed`, a retro or your correction (staged) |
| `memory/INDEX.md` (root, and `seeds/<name>/memory/`) | one line per committed memory, most valuable first, with when to read it | `memory` via `write.py` |
| `memory/committed/<date>-<description>.md` | a memory: frontmatter (type, date, source, seen) and why it holds; stated by you, or seen by two tasks | `memory` via `write.py` |
| `memory/pending/<date>-<description>.md` | a memory seen once, waiting for a second sighting; never indexed | `memory` via `write.py` |
| `memory/rejected.md` | proposals you declined; a retro reads it first | `memory`, `sync` via `write.py` |
| `README.md`, `AGENTS.md`, `CLAUDE.md` | placeholders about your garden, for people and agents | you |

Memory is written directly and committed locally. Everything else changes on a local `garden/*` branch, which you merge (or open as a PR with `sync`).

## garden's (`garden/docs/upstream-paths.txt`)
| File | What it is |
|---|---|
| `SKILL.md` | the router: the only skill your tools see, and garden's only file at the root |
| `garden/skills/memory/` | reading and writing memory, retros, staging; `write.py` is the gate for every write (mandatory) |
| `garden/skills/escalate/` | when and how to ask you; `block.sh` builds the question block |
| `garden/skills/handoff/` | calling or passing to another seed; `call.sh` enforces `access`, `check.sh` is the backstop |
| `garden/skills/sync/` | pull, push memory, open PRs, take upstream releases; only when asked |
| `garden/skills/new-seed/` | the interview that builds or changes seeds |
| `garden/docs/` | for people: the README, this reference, the tutorial, the spec, MIGRATING, decisions |
| `garden/check/` | the validator and the optional pre-commit script |
| `garden/dev/` | maintainer files (fixtures, tests, proofs), inert in your copy |
| `.github/workflows/garden.yml`, `.gitattributes` | CI, and the union merge for memory files: at the root, because only there do they work |

Changes to these come from upstream releases (through `sync`), or from your own root-tier changes, which a retro stages separately.

## Access levels
| `access` | The seed, when another seed calls it |
|---|---|
| `read-only` | reads and searches only: no edits, no shell |
| `edit` | also edits and writes files: no shell |
| `full` (default) | everything your tool's settings allow |

Enforced by your tool through `garden/skills/handoff/call.sh`; details per tool in `garden/skills/handoff/access.md`.
