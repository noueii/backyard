# This repo is a garden

It is the `garden` skill: the router is `SKILL.md`, and the framework is in `garden/` (its docs: `garden/docs/`). If you were sent here by a task, start with `SKILL.md`.

Working in this repo:
- Change seeds, docs and skills only as `SKILL.md`'s "Changes to the garden" says: on a `garden/*` branch outside the repo, never in the live clone, except memory.
- Write memory only through `python3 garden/skills/garden-memory/write.py`. Push, pull and open PRs only through `garden/skills/garden-sync/SKILL.md`, and only when the owner asks. Never merge a PR.
- A `SKILL.md` goes only at the root and in a skill's own folder (`garden/skills/<s>/`, `skills/<s>/`, `seeds/<x>/skills/<s>/`). Never add a `.git` folder, clone or worktree inside the repo.
- Check before committing: `python3 garden/check/validate.py .`
- Maintaining the framework itself (noueii/garden)? Read `garden/dev/AGENTS.md`.
