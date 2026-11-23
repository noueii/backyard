---
name: sync
description: "Syncs the garden with origin and upstream: pulls (fast-forward only, keeping local memory), pushes memory commits, opens PRs for staged changes, and stages upstream releases as a root PR. Never merges. Use when a seed's text says to sync, or when the owner asks; never otherwise."
metadata: { seeds-format: "1.0" }
---
# sync

Paths are relative to the garden root. **Run sync only when a seed's text says to, or when the owner asks.** Never from memory or rsi, never on your own initiative, never on a schedule. memory and rsi keep everything local until then.

## Run it
```sh
bash garden/skills/sync/sync.sh status      # what each step would do; changes nothing
bash garden/skills/sync/sync.sh all         # pull, memory, upstream, staged, decisions; stops at the first failure
```
Run `status` first when the owner asked in general terms ("sync the garden"), and say what will happen. A seed whose text names a step ("sync memory at the end") runs just that step: `sync.sh memory`, after `sync.sh pull`. Run it after the depth-0 memory commit, from the live clone, on its default branch.

## The steps
1. **pull:** `git fetch origin`. Behind: fast-forward. Diverged: if every local-only commit touches memory paths only (`MEMORY.md`, `memory/`, `seeds/*/MEMORY.md`, `seeds/*/memory/`), they are replayed onto origin with `git rebase`; `.gitattributes` gives `MEMORY.md`, `runs.md` and `unrouted.md` the `union` merge driver, so lines added on both sides are all kept. Anything else is refused. Never a merge commit on the default branch.
2. **memory:** pushes the local commits to origin's default branch, only if every commit ahead touches memory paths only. Never force.
3. **upstream:** fetches noueii/garden (`upstream`) and its newest release tag of the same major as `SKILL.md`'s `metadata.version` (`v2.*`). If you have it, nothing to do. Otherwise it merges the tag on a new root-tier branch, `garden/<date>-upstream-<tag>-root`, in a stage outside the repo, and runs the validator there. The default branch is not touched: the release reaches it when the owner merges the PR, and the next `pull` fast-forwards to it. (A garden with no origin and no commits of its own fast-forwards instead.)
4. **staged:** for each finished local `garden/*` branch (rsi's stages, the upstream branch): push it and open its PR with `gh pr create --fill`, whose title and body are the branch's commit message. One PR per branch, so the seeds tier and the root tier stay separate. A branch that already has a PR is left alone.
5. **decisions:** records each `garden/*` PR closed without merging that `memory/rejected.md` doesn't hold yet (`- <date> | <title> (<url>) | closed without merging`, through write.py). Commit it like any memory (`memory: rejected proposals`) and push it with `sync.sh memory`. rsi reads that list and won't propose those again without new evidence.

## When it stops
- **exit 1 (refused or failed):** report the printed reason and stop. Common ones: uncommitted changes (commit memory first), not on the default branch, local non-memory commits on the default branch (they belong on a `garden/*` branch: ask the owner), origin's copy of a branch differs (never force).
- **exit 3 (upstream conflicts):** the stage path and files are printed. In the stage, keep upstream's version of each conflicted file and re-apply your local change only if it is still needed. If unsure, ask the owner (escalate's block) or stop. Then `git -C <stage> commit -F <message file it printed>`, add `## Conflicts` to the PR body listing each file and what you kept, run `python3 <stage>/garden/check/validate.py <stage>`, `git worktree remove <stage>`, and run `sync.sh staged`.
- **No origin, or no gh:** it says what it skipped. Branches stay local; tell the owner where they are.
- **A new major** (of `version` or `seeds-format`): sync does not take it on its own; it prints its tag. The release's `garden/docs/MIGRATING.md` says how to take it and migrate your files. That migration goes on the same upstream branch, and its PR says it touches seeds, docs or memory.

## Never
- Merge a PR, push with `--force`, push anything but memory to the default branch, or run without being asked.
- Rebase or reset commits that touch more than memory.

## Report
`## Synced`: one line per step with what happened, the PR links, and anything left for the owner (PRs to review, conflicts, refusals).
