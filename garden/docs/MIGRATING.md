# Migrating

How to take a new major release of garden. sync stages releases of your current major on its own; a new major it only announces, so you take it by hand, once, as below.

## 2.x → 3.0.0: memory as files, rsi merged into `garden-memory`, skills as `SKILL.md` (`seeds-format` 2.0)
Memory is one file per memory, and `rsi` is part of `garden-memory` ([why](decisions/0003-memory-layout.md)). Every skill inside the garden is a standard `SKILL.md`, and garden's are named `garden-*` ([why](decisions/0004-skill-md.md)). A 2.x garden fails the 3.0.0 validator until its memory is moved, so take the release and the migration on one branch:
```sh
git fetch upstream --tags
git switch -c garden/$(date +%Y%m%d-%H%M)-upstream-v3-0-0-root
git merge v3.0.0
```
| Was | Now |
|---|---|
| `MEMORY.md`, `seeds/<x>/MEMORY.md` | `memory/INDEX.md`, `seeds/<x>/memory/INDEX.md`, plus a file in `committed/` per line |
| `memory/lessons.md` | a file in `pending/` per lesson (its `seen` runs become `seen` tasks) |
| `memory/<topic>.md` | the body of the memory that linked it |
| `runs.md`, `unrouted.md`, `archive.md` | deleted (git history keeps them) |
| `garden/skills/rsi/` | `garden/skills/garden-memory/` (`retro.md`, `stage.md`) |
| `garden/skills/<s>/ENTRY.md` (memory, escalate, handoff, sync, new-seed) | `garden/skills/garden-<s>/SKILL.md` ([why](decisions/0004-skill-md.md)) |
| `skills/<s>/ENTRY.md`, `seeds/<x>/skills/<s>/ENTRY.md` (yours) | `SKILL.md` in the same folder |

- **Each MEMORY.md line** becomes a committed file through write.py, keeping its date. A line you stated: `echo "<the fact, and why>" | python3 garden/skills/garden-memory/write.py new memory <description> --type fact --source 'owner: "<the line>"' --owner --when "<condition>" --date <its date>`. A promoted lesson: write it as pending with `--seen <run>` for one of its runs, then `seen` the other, then `promote`. Keep the old order (most valuable first) in INDEX.md.
- **Delete** `MEMORY.md`, `memory/.gitkeep`, `memory/lessons.md` (once moved), topic files (once folded in), and every `runs.md`, `unrouted.md` and `archive.md`. A recurring unrouted task worth a seed can become a pending memory (`no-seed-for-<kind>`).
- **Seeds** listing `rsi` in `skills`: remove it. Seeds listing `escalate`, `handoff`, `sync` or `new-seed` now list `garden-escalate`, `garden-handoff`, `garden-sync`, `garden-new-seed`. Text naming `garden/skills/<s>/` now names `garden/skills/garden-<s>/`: `grep -rnE 'skills/(rsi|memory|escalate|handoff|sync|new-seed)\b|ENTRY\.md' seeds docs skills`.
- **Your own skills** (`skills/<s>/`, `seeds/<x>/skills/<s>/`): `git mv ENTRY.md SKILL.md` in each; a vendored one can take back its upstream `SKILL.md`. Their names may not be `garden` or start with `garden-`. opencode lists them as skills of their own, so say in each description that it is used through your garden.
- **SKILL.md's `seeds-format`** is `"2.0"` after the merge. Check with `python3 garden/check/validate.py .` and `python3 garden/skills/garden-memory/write.py check memory`, then commit and merge the branch like any root PR.

## 1.x → 2.0.0: the framework moved into `garden/`
garden's own files left the root for one folder, `garden/` ([why](decisions/0002-framework-folder.md)). Your seeds, docs and memory don't move, and their format (`seeds-format` 1.0) is unchanged.

| Was | Now |
|---|---|
| `skills/memory/`, `rsi/`, `escalate/`, `handoff/`, `sync/`, `new-seed/` | `garden/skills/<same>/` |
| `spec/SPEC.md`, `spec/upstream-paths.txt` | `garden/docs/SPEC.md`, `garden/docs/upstream-paths.txt` |
| `guide/tutorial.md`, `guide/reference.md` | `garden/docs/tutorial.md`, `garden/docs/reference.md` |
| `check/`, `dev/` | `garden/check/`, `garden/dev/` |
| `dev/decisions/` | `garden/docs/decisions/` |
| `README.md` (about garden) | `garden/docs/README.md`; the root `README.md`, `AGENTS.md` and `CLAUDE.md` are now yours |

**Take it** on a branch, from the live clone, then merge it like any root PR:
```sh
git fetch upstream --tags
git switch -c garden/$(date +%Y%m%d-%H%M)-upstream-v2-0-0-root
git merge v2.0.0            # git follows the renames
python3 garden/check/validate.py .
```
- **Your own shared skills** stay in `skills/<s>/`, at the root. If git put one of them in `garden/skills/`, move it back: `garden/` holds only garden's skills, and the validator says so.
- **A root-tier change you made** to a garden skill moves with its file; a conflict is resolved like any upstream one (`garden/skills/garden-sync/SKILL.md`, exit 3).
- **Paths in your own text** (seeds, docs, workflow.md) that name garden's files, such as `skills/escalate/block.sh`, now start with `garden/`. Find them with `grep -rnE '(^|[^/])(skills/(memory|rsi|escalate|handoff|sync|new-seed)|spec/|check/|guide/)' seeds docs skills`.
- **The pre-commit hook**, if you linked it: `ln -sf ../../garden/check/pre-commit.sh .git/hooks/pre-commit`.
- **README.md, AGENTS.md, CLAUDE.md:** the merge replaces garden's old README with a short placeholder; keep it or write your own. From now on releases never touch them.
