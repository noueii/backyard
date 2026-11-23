# Migrating

How to take a new major release of garden. sync stages releases of your current major on its own; a new major it only announces, so you take it by hand, once, as below.

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
- **A root-tier change you made** to a garden skill moves with its file; a conflict is resolved like any upstream one (`garden/skills/sync/ENTRY.md`, exit 3).
- **Paths in your own text** (seeds, docs, workflow.md) that name garden's files, such as `skills/escalate/block.sh`, now start with `garden/`. Find them with `grep -rnE '(^|[^/])(skills/(memory|rsi|escalate|handoff|sync|new-seed)|spec/|check/|guide/)' seeds docs skills`.
- **The pre-commit hook**, if you linked it: `ln -sf ../../garden/check/pre-commit.sh .git/hooks/pre-commit`.
- **README.md, AGENTS.md, CLAUDE.md:** the merge replaces garden's old README with a short placeholder; keep it or write your own. From now on releases never touch them.
