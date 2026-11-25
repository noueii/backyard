# 0002: the framework in one folder, `garden/` (2026-11-23)

Status: **accepted** (the owner's decision). **Amended by [0004](0004-skill-md.md)** (garden 3.0.0): garden's skills are `garden/skills/garden-<s>/SKILL.md`, so `SKILL.md` is no longer garden's only file of that name. Amends [0001](0001-seeds.md) §1, §7 and §8 of the spec. Release: garden **2.0.0**; `seeds-format` stays **1.0**.

## Decision
garden is a framework, and its files no longer sit beside the owner's. Everything garden ships lives in one folder, `garden/`, except the router and two files that only work at the root.

```
<root>/
  SKILL.md         the router: garden's only file at the root that is not an exception below
  garden/          the framework, self-contained
    skills/        memory, rsi, escalate, handoff, sync, new-seed (ENTRY.md each)
    docs/          README, tutorial, reference, SPEC.md, MIGRATING.md, upstream-paths.txt, decisions/
    check/         validate.py, pre-commit.sh
    dev/           maintainer files: AGENTS.md, tests, fixtures, proofs
  docs/ seeds/ MEMORY.md memory/   the owner's, unchanged
  skills/          the owner's own shared skills (optional; upstream ships none)
  README.md AGENTS.md CLAUDE.md    the owner's: placeholders shipped once, frozen upstream
  .github/workflows/garden.yml  .gitattributes   garden's root exceptions
```

**Why:** with garden's eleven root entries mixed into the owner's five, a user could not tell at a glance what is theirs, and every new framework file landed in their space. One folder makes the line obvious, lets the validator enforce it, and shrinks the ownership list to `SKILL.md`, `garden/` and two exceptions.

## What moved (with `git mv`, so history follows)
| Was | Now |
|---|---|
| `skills/{memory,rsi,escalate,handoff,sync,new-seed}/` | `garden/skills/…` |
| `spec/SPEC.md`, `spec/upstream-paths.txt` | `garden/docs/` |
| `guide/tutorial.md`, `guide/reference.md` | `garden/docs/` |
| `README.md` (about garden) | `garden/docs/README.md` |
| `check/` | `garden/check/` |
| `dev/` (maintainer `AGENTS.md`, tests, fixtures, proofs) | `garden/dev/` |
| `dev/decisions/` | `garden/docs/decisions/` |

Every path reference moved with them: the router, each ENTRY.md, the scripts (`write.py`, `call.sh` and `sync.sh` now find the root three folders up), CI, the spec, the guide, 0001 and the fixtures.

## What stays at the root, and why
- **`SKILL.md`**: every tool finds a skill only by a `SKILL.md` at the top of the installed folder (0001 §1). It is the only `SKILL.md` anywhere, `garden/` included: opencode would register a nested one.
- **`.github/workflows/garden.yml`**: GitHub reads workflows only from `.github/workflows/` at the repo root. It stays garden-owned (listed in `upstream-paths.txt`) rather than a file the user copies, so a release can update CI along with the validator it runs. Its name keeps it apart from the owner's own workflows.
- **`.gitattributes`**: kept, because it is still needed. It gives the memory files (`MEMORY.md`, `memory/*`, `seeds/*/MEMORY.md`, `seeds/*/memory/*`) the `union` merge driver, which sync's rebase of memory commits relies on (`test-scripts.sh` checks both sides' lines survive). Git applies a `.gitattributes` only to paths at or below its own folder, and the memory files are outside `garden/`, so it can only work at the root. Setting it through `core.attributesFile` from sync instead would leave a plain `git pull --rebase` (the README's other update path) without it.
- **`README.md`, `AGENTS.md`, `CLAUDE.md`** are now **the owner's**: short placeholders upstream ships once and never changes (frozen by hash in `check-upstream.sh`, like `docs/INDEX.md`). The README points to `garden/docs/`; AGENTS.md keeps the rules for any agent working in a garden. The maintainer instructions are `garden/dev/AGENTS.md` (with a `CLAUDE.md` that imports it).

## The owner's own shared skills
Before, `skills/` held garden's skills and the owner's own side by side. Now garden's are in `garden/skills/` and the owner's stay in `skills/` at the root, which upstream never ships. A bare skill name resolves to `garden/skills/<s>/`, `skills/<s>/` or the seed's `skills/<s>/`; the owner's may not shadow garden's. They are seeds-tier changes for rsi, since only `upstream-paths.txt` is the root tier.

## The validator enforces the line
`garden/check/validate.py`, in every garden:
- no garden-owned file outside `SKILL.md`, `garden/` and the exceptions: none of the 1.x root paths (`spec/SPEC.md`, `check/validate.py`, …) and no garden skill name in `skills/`; `upstream-paths.txt` may list only `SKILL.md`, `garden/`, `.github/workflows/garden.yml` and `.gitattributes`, and must list the first two;
- no owner content inside `garden/`: it holds only `skills/`, `docs/`, `check/` and `dev/`; `garden/skills/` only garden's six skills; no `seeds/` folder, `MEMORY.md` or `INDEX.md`, and no `SEED.md` outside new-seed's examples;
- still no `SKILL.md` below the root in any casing, `garden/` included.

`garden/dev/check-upstream.sh`, in noueii/garden only, adds the complete check: every shipped file is garden-owned or a frozen placeholder, and no root `skills/` ships.

## Versions
- **`version` 2.0.0:** garden's paths are an interface (the owner's seed text names scripts, the pre-commit link, CI), so moving them is a major release. sync takes releases of the current major only, so 1.x gardens get a printed notice, not a PR; `garden/docs/MIGRATING.md` says how to take it. There are no users yet, so the notes are short.
- **`seeds-format` stays 1.0:** no file the owner writes changes format or place.

## Checked
`validate.py`, `check-upstream.sh`, `test-validate.sh` (new fixtures for each rule), `test-scripts.sh`, and in a temp HOME `prove-install.sh` (pi, omp and opencode each discover exactly one new skill, `garden`; no internal skill reaches the model) and `prove-access.sh`.
