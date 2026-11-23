# This repo is a garden

It is the `garden` skill: the router is `SKILL.md`, and its format is `spec/SPEC.md`. If you were sent here by a task, start with `SKILL.md`.

Working in this repo:
- Change seeds, docs and skills only through `skills/new-seed/ENTRY.md` or `skills/rsi/ENTRY.md`, which stage changes on a `garden/*` branch outside the repo (`skills/rsi/stage.md`). Never hand-edit the live clone, except memory.
- Write memory only through `python3 skills/memory/write.py` (`skills/memory/ENTRY.md`).
- Push, pull and open PRs only through `skills/sync/ENTRY.md`, and only when the owner asks. Never merge a PR.
- Never add a file named `SKILL.md` (any casing) below the root, or a `.git` folder, clone or worktree inside the repo.
- Check before committing: `python3 check/validate.py .`
- Maintaining noueii/garden itself? Read `dev/AGENTS.md`.
