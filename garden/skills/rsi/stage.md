# The stage

Behaviour changes are never made in the live clone. They are made in a **stage**: a git worktree outside the repo and outside every skills folder (opencode scans dot folders and would find a second `SKILL.md` inside the repo).

## 1. Which tier
- **root:** a path listed in `garden/docs/upstream-paths.txt` (`SKILL.md`, `garden/`, ...). These are upstream's files; a change to them may also be worth proposing upstream.
- **seeds:** everything else that is not memory: `seeds/`, `docs/`, your own `skills/`, your root files.
- **neither:** memory paths (`MEMORY.md`, `memory/`, `seeds/*/MEMORY.md`, `seeds/*/memory/`) are written directly, never staged.

One task gets at most one stage per tier, so the two tiers become separate PRs.

## 2. Open a stage (once per task and tier)
```sh
R="$(git -C <garden root> rev-parse --show-toplevel)"; N="$(basename "$R")"
B="garden/$(date +%Y%m%d-%H%M)-<task>-<tier>"            # tier: seeds | root
T="${XDG_STATE_HOME:-$HOME/.local/state}/garden/$N/stage/${B#garden/}"
git -C "$R" worktree add -q "$T" -b "$B"
```
- Reuse the stage if this task already opened one for the tier.
- **Called seeds** stage into their caller's stage: the path is in the call prompt. A called seed with access below `full` doesn't stage at all: it returns `## Proposed changes` (file, change, evidence) and the caller stages them.
- Edit only inside `$T`. Keep `seeds/INDEX.md` equal to SEED.md (`when`, `group`), and each `docs/INDEX.md` equal to its folder, in the same change.

## 3. Finish a stage (depth 0, at the end of the task)
1. **Validate:** `python3 "$T/garden/check/validate.py" "$T"` (if python3 and PyYAML are there; say so if not). Fix what it reports, or drop the change.
2. **Commit locally**, with the future PR's title and body as the message (sync opens the PR with `gh pr create --fill`):
   - **Title:** `seeds(<seed>[,<seed>]): <summary>`, or `root: <summary>`.
   - **Body:**
     - `## Evidence`: the quoted run and unrouted lines, and owner quotes;
     - `## Changes`: per finding, its category, what changed and its evidence;
     - `## Removed`: what was deleted or compacted;
     - `## Budgets`: before → after word counts of everything always loaded;
     - for the root tier, `## Upstream`: whether it should also be proposed to noueii/garden.
   ```sh
   git -C "$T" add -A && git -C "$T" commit -q -F <message file>
   git -C "$R" worktree remove "$T"
   ```
3. **Keep the branch.** Never push it and never merge it. The report lists it under `## Staged`.

Nothing changed in the stage: remove the worktree and delete the branch (`git -C "$R" branch -D "$B"`).

## 4. Without git
If the garden is not a git clone (a read-only trial), nothing can be staged: describe each proposed change under `## Proposed changes` in the report, with its evidence.
