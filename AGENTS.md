# This repo is a backyard

It is the `backyard` skill: the router is `SKILL.md`, and the framework is in `backyard/` (its docs: `backyard/docs/`). If you were sent here by a task, start with `SKILL.md`.

Working in this repo:
- Change seeds, docs and skills only as `SKILL.md`'s "Changes to the backyard" says: on a `backyard/*` branch outside the repo, never in the live clone, except memory.
- Write memory only through `python3 backyard/skills/backyard-memory/write.py`. Push, pull and open PRs only through `backyard/skills/backyard-sync/SKILL.md`, and only when the owner asks. Never merge a PR.
- A `SKILL.md` goes only at the root and in a skill's own folder (`backyard/skills/<s>/`, `skills/<s>/`, `seeds/<x>/skills/<s>/`). Never add a `.git` folder, clone or worktree inside the repo.
- Check before committing: `python3 backyard/check/validate.py .`
- Maintaining the framework itself (noueii/backyard)? Read `backyard/dev/AGENTS.md`.
