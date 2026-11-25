# Tutorial: your backyard

You'll make your own backyard, install it into your tools, grow two seeds that work together, and see how a backyard improves itself and takes updates. Allow 20 minutes. You need git, python3 with PyYAML, and at least one of Claude Code, opencode, pi or omp. `gh` is optional (only for pushing and pull requests).

## 1. Make your backyard
A backyard is a copy of [noueii/backyard](https://github.com/noueii/backyard). Make it **private**: your memory lives in it.
```sh
git clone https://github.com/noueii/backyard.git ~/src/backyard
cd ~/src/backyard
git remote rename origin upstream                      # noueii/backyard: where updates come from
gh repo create <you>/backyard --private --source . --push   # your copy: origin
```
No GitHub? Skip the last line: the backyard works locally, and `backyard-sync` just skips pushing. A GitHub fork works too, but a fork of a public repo is public, and so would be your memory.

One backyard per environment: if you keep work and personal apart (two WSL distros, two machines), make one backyard in each.

## 2. Install it
Two symlinks, so every tool loads the same clone:
```sh
mkdir -p ~/.agents/skills ~/.claude/skills
ln -s ~/src/backyard ~/.agents/skills/backyard     # opencode, pi, omp
ln -s ~/src/backyard ~/.claude/skills/backyard     # Claude Code (omp and opencode see both and keep one)
```
Claude Code, pi and omp now list one skill, `backyard`. The skills inside are standard `SKILL.md` files the router reads by path; opencode lists them too, as `backyard-memory`, `backyard-sync` and so on (and your seeds' own skills), each described as used through the backyard.

**Optional:** to start every task with the backyard, add this line by hand to each tool's global instructions (`~/.claude/CLAUDE.md`, `~/.config/opencode/AGENTS.md`, `~/.pi/agent/AGENTS.md`, `~/.omp/agent/AGENTS.md`):
> Start every task with the `backyard` skill, unless your prompt says you were called as a seed inside a running task.

The "unless" matters: a seed called by another seed runs as a sub-agent, which reads the same global file.

**Just trying it?** `npx skills add noueii/backyard -g` installs a read-only copy: no git, so memory and self-improvement save nothing (they go into each report instead).

## 3. Your first seed
Start your tool in a project and give it a task you do often, for example "review the diff on this branch". The router finds no seed that fits, so it offers to make one (`backyard-new-seed`). Say yes. It asks one question at a time, each with its recommendation first:
1. the purpose, in one sentence;
2. `when`: the line the router will match future tasks against;
3. the docs it should read;
4. skills (shared, its own, or ones you installed elsewhere);
5. whether it calls other seeds;
6. its `access`: a reviewer is `read-only`;
7. whether it asks you when stuck (`backyard-escalate`) or decides and records;
8. whether it should sync the backyard;
9. facts it should start with.

It builds the seed on a local branch, `backyard/<date>-<task>-seeds`, checks it with the validator, and commits. Nothing is merged for you. Look at it:
```sh
cd ~/src/backyard
git branch --list 'backyard/*'
git log -p -1 backyard/<the branch>
```
Then take it: with an `origin`, through its pull request (ask to "sync the backyard", section 6, then merge the PR on GitHub); with no `origin`, merge it locally with `git merge backyard/<the branch>`. (With an `origin`, keep your default branch to memory commits and merged PRs, so sync can always fast-forward it.)
The seed is `seeds/reviewer/SEED.md`: a short frontmatter and plain prose. Change it any time by asking for a change ("change the reviewer so it ..."): `backyard-new-seed` stages that too.

## 4. A second seed that calls the first
Seeds compose: a seed can run another through `backyard-handoff`. Ask for a "task manager" seed that plans, implements, and then calls `reviewer`. `backyard-new-seed` writes its order in your words, in SEED.md or a free-form `workflow.md`; there's an example in `backyard/skills/backyard-new-seed/examples/task-manager/`.

When the task manager calls the reviewer, handoff starts it as a fresh session of the same tool with **only read tools**, because the reviewer is `read-only`. Your tool enforces that (it never offers the reviewer a shell or a write tool), and a git snapshot checks afterwards that nothing changed. What each tool enforces is in `backyard/skills/backyard-handoff/access.md`.

## 5. It remembers, and improves itself
A seed writes memory only when something is worth it: you correct it or tell it a fact, something fails, or something surprises it. A routine run writes nothing. Each memory is one small file in `memory/` (shared) or `seeds/<name>/memory/`:
```
memory/
  INDEX.md      one line per committed memory: what it is, and when to read it
  committed/    2026-11-23-api-tests-need-make-db.md   what you said, or what two tasks saw
  pending/      2026-11-24-reviewer-slow-on-big-diffs.md   seen once, waiting for a second sighting
```
What you state goes straight to `committed/`. Anything else waits in `pending/` until a second task sees it. Seeds read `INDEX.md` at the start, and a memory only when its line fits the task.

A rule is never memory: your correction of how a seed behaves ("never do X") is staged at once as a change to its docs, on a local `backyard/*` branch, for you to review.

When a pending memory is seen again, or memory nears its budget, or you ask, the seed runs a **retro**: it promotes what two tasks saw, removes what is stale, and stages at most five changes to docs and seeds, each with its evidence, always proposing at least one removal. If you turn a proposal down, it goes to `memory/rejected.md`, and won't be proposed again without new evidence.

Memory is committed **locally** at the end of each task, and never pushed except by `backyard-sync`. Every memory write goes through `backyard/skills/backyard-memory/write.py`, which refuses secrets, invisible characters and instruction-like text, and fails when memory is full, so the retro compacts it first; the validator checks the same on every commit.

## 6. Sync: push, pull, and update
Nothing leaves your machine until you ask. Say "sync the backyard" (or give a seed a line such as "sync at the end of every run"). `backyard-sync` shows what it will do, then:
1. pulls `origin`, fast-forward only, replaying your local memory commits on top;
2. pushes those memory commits to your default branch;
3. stages a new backyard release from `upstream` on its own branch;
4. pushes each staged branch and opens a pull request for it;
5. records proposals you closed without merging in `memory/rejected.md`.

It never merges a pull request: you do. You can run it yourself:
```sh
bash ~/src/backyard/backyard/skills/backyard-sync/sync.sh status
```

## 7. Check it
```sh
python3 ~/src/backyard/backyard/check/validate.py ~/src/backyard
```
Your backyard's CI runs the same check on every push. To run it on every local commit too:
```sh
ln -s ../../backyard/check/pre-commit.sh ~/src/backyard/.git/hooks/pre-commit
```

## Where next
- [The reference](reference.md): every file kind in a backyard, in a line or two.
- [The spec](SPEC.md): the exact format.
- [The decision record](decisions/0001-seeds.md): why it is built this way.
