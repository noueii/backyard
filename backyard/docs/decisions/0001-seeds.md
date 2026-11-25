# 0001: seeds (2026-11-23)

**Renamed by [0005](0005-backyard.md)** (backyard 4.0.0): the standard garden is now **backyard**: the router `backyard`, the folder `backyard/`, the skills `backyard-*`, the repo noueii/backyard. This record keeps the names and paths it was decided with.

Status: **accepted**. The owner accepted the plan in psai's ADR 0014 ("flakes"), with the changes recorded in "What changed from psai 0014" below. This ADR is that plan, renamed and updated for a fresh repo. Nothing in it was built in psai, which is being archived.

**Amended by [0002](0002-framework-folder.md)** (garden 2.0.0): garden's own files moved into one folder, `garden/`. The layout diagram below is the layout as first decided; every other path in this record is updated to the new one.

**Amended by [0004](0004-skill-md.md)** (garden 3.0.0): the skills inside a garden are standard `SKILL.md` files, garden's named `garden-*`; "exactly one `SKILL.md` per installed folder" (§1) no longer holds, and opencode lists the nested ones.

**Amended by [0003](0003-memory-layout.md)** (garden 3.0.0, `seeds-format` 2.0): memory is one file per memory (`memory/INDEX.md`, `committed/`, `pending/`), with no `MEMORY.md`, run lines, lessons, archive or unrouted file, and `rsi` is merged into `memory`. What this record says about those is the design as first decided.

**Credits.** This plan was written in [noueii/psai](https://github.com/noueii/psai):
- the structure and build plan: ADR 0014, branch [`plan-flakes`](https://github.com/noueii/psai/blob/plan-flakes/docs/decisions/0014-flakes.md);
- the tool-discovery research: ADR 0013 §1–2, branch [`plan-one-skill`](https://github.com/noueii/psai/blob/plan-one-skill/docs/decisions/0013-one-stack-one-skill.md);
- psai 4.0's escalation block, its `check-diff.sh`, and its no-AI proof helpers (`fake-model.py`, `git-http.py`), which garden adapts.

## Decision
A **seed** is a bot: one purpose, with what it needs. A user's seeds live in one git repo, the **garden**, and **the garden's root folder is the only skill** installed into their tools.

```
garden/                     the user's repo (a copy of noueii/garden); the root is the one skill
  SKILL.md                  the router: the ONLY SKILL.md. Broad, model-invoked. Picks a seed and hands over
  skills/                   shared internal skills, one folder each, entry file ENTRY.md (never SKILL.md)
    memory/                 MANDATORY for every seed
    rsi/                    MANDATORY for every seed (recursive self-improvement)
    escalate/               optional: when and how to ask the owner; the report format
    handoff/                optional: call another seed as a sub-agent, with its access level enforced
    sync/                   optional: sync the garden with origin and upstream, only when asked
    new-seed/               builds or changes seeds with the owner, one question at a time
  docs/                     the owner's rules and reference for every seed, with INDEX.md
  MEMORY.md  memory/        shared memory, in Orca's format
  seeds/
    INDEX.md                one line per seed: what the router reads
    <name>/
      SEED.md               who this bot is (frontmatter + plain prose)
      workflow.md           OPTIONAL, free-form: the procedure in the owner's own words
      skills/<s>/ENTRY.md   the seed's own bundled skills
      docs/                 the seed's own docs, with INDEX.md (they override root docs)
      MEMORY.md  memory/    the seed's own memory, including memory/runs.md
  spec/  check/  guide/     the format, the validator, the human guide
  dev/                      maintainer files (decisions, fixtures, proofs), shipped inert
```

- **No roles anywhere.** A planner, a coder, a QA or a reviewer is just another seed. A "workflow" is a seed (say `task-manager`) whose SEED.md, or an optional free-form `workflow.md`, says in the owner's words which seeds it calls and in what order. garden enforces no workflow format: `new-seed` offers guidance and short examples, never a schema.
- **Seeds compose:** a seed calls other seeds through `handoff`.
- **No SKILL.md below the root, in any casing.** Internal skills use `ENTRY.md` (§2).
- **Install:** clone, then symlink the root into `~/.claude/skills/garden` and `~/.agents/skills/garden`. **Update:** `sync`, or `git pull`. Optionally, add one line to each tool's global instructions.
- **No** per-tool plugins, manifests, hooks, extensions, custom CLI, runtime or AI evals. CI runs deterministic, structural checks only.
- **Hard guarantees only where they are cheap:** escalate's fixed block (built by a script), and `access` levels enforced per tool when one seed calls another (§6).
- **Memory is always written locally.** rsi and memory never push and never open PRs. Pushing memory, pushing staged behaviour changes as PRs, and pulling updates are `sync`'s job, and sync runs only when a seed's text says so or the owner asks (§5.5).
- **RSI tiers:** memory is written directly (locally). Seed behaviour (`seeds/**`, `docs/**`) is staged on ONE branch per task. The root (`SKILL.md`, `garden/`, the other upstream paths) gets its own branch. sync turns each branch into a PR.
- **Orca:** an Orca bot can host a seed. Its SOUL.md says "you are seed `<name>`". SEED.md ≈ SOUL.md and MEMORY.md ≈ MEMORY.md, on purpose.
- **Work and personal are separate WSL distros**, so there is one garden per environment.
- **noueii/garden is the upstream:** the router, the shared skills, empty `docs/`, `memory/` and `seeds/`, a spec, a validator, CI and a human guide. A user's garden starts as a copy of it and takes its releases through `sync`.

**Why:** psai 4.0 shipped six top-level skills and five packaging channels. Its naming rules exist only because tools merge skills into one flat list, and it shipped a YAML state machine with a trace script and a simulator: machinery the owner does not want. With one root skill nothing internal can collide, and every tool already discovers it. With seeds calling seeds, one concept (a bot with a purpose, docs and memory that improves itself) replaces workflows, roles, guides, templates and knowledge layers.

**Compared with pstack** (`cursor/plugins/pstack`, read 2026-11-23). Its `poteto-mode` routes each task to one of 22 playbooks and runs sibling skills by path. We keep the shape (one entry routes, everything else is loaded by path) and change three things:
- pstack's 39 skills are each discovered on their own; ours are invisible behind one root.
- `poteto-mode` is manual (`disable-model-invocation`); our router is model-invoked.
- pstack's playbooks are fixed prose by one author; our seeds are the owner's, and each rewrites itself from evidence (rsi).

## What changed from psai 0014 (the owner's changes)
1. **"flake" is renamed "seed"** everywhere: `seeds/<name>/SEED.md`, `seeds/INDEX.md`, `new-seed`, `seeds-format`. The repo is the **garden**, and the router skill is named **`garden`** (§12, Q2).
2. **Memory is always written locally.** memory commits locally; rsi stages on local branches. A new optional shared skill, **`sync`**, does every push and pull (§5.5).
3. **Access levels replace `may_change`:** `access: read-only | edit | full` (default `full`), enforced per tool by handoff, with a git snapshot check as backstop (§6).
4. **Q5–Q7 as recommended:** the router reads `seeds/INDEX.md`; docs say clone + symlink, and `npx skills add` gets one line as a read-only trial; maintainer files sit under `garden/dev/`, shipped inert.
5. **A new repo:** nothing to migrate or remove, so 0014's cut-over PR and removal table are gone. The earlier psai ADRs stay in psai; this is garden's ADR 0001.
6. **No LICENSE yet:** the owner chose none for psai; the README flags it as undecided.
7. **Memory safety (added during the build, owner-approved from research on Letta, OpenClaw and Hermes):** a promotion gate, no promotion of untrusted text, hard budgets, and a rejected list (§13).

---

## 1. Discovery per tool (verified 2026-11-23, from psai 0013 §2)
| | Claude Code 2.1.330 | opencode 1.18.30 | pi 0.80.2 / 1.6.0 | omp 18.11 / 19.1 |
|---|---|---|---|---|
| user skill dirs | `~/.claude/skills/` | `~/.config/opencode/skill(s)/`, `~/.claude/skills/`, `~/.agents/skills/` | `~/.pi/agent/skills/`, `~/.agents/skills/` | `~/.omp/agent/skills/`, `~/.agents/skills/`, `~/.claude/skills/` |
| depth | `<dir>/<name>/SKILL.md` | **recursive** `skills/**/SKILL.md`, follows symlinks, includes dot folders | recursive, but **stops at the first folder with a SKILL.md** | **one level** |
| a nested SKILL.md in our folder | ignored (proven by `garden/dev/prove-install.sh`) | **registered as another skill** | ignored | ignored |
| description limit | listing truncates at 1536 characters | none found | 1024 (warns) | none found |
| symlinked folder | yes | yes | yes, deduped by real path | yes, deduped by real path |
| global instructions file | `~/.claude/CLAUDE.md` | `~/.config/opencode/AGENTS.md` | `~/.pi/agent/AGENTS.md` | `~/.omp/agent/AGENTS.md` |

So exactly one `SKILL.md` per installed folder is required, not just tidy. `garden/dev/prove-install.sh` confirms it in a temp HOME: pi, omp and opencode discover exactly one new skill, `garden`; all four send it, and no internal skill, to a fake model; a nested `SKILL.md` is ignored by Claude Code, pi and omp and registered by opencode. One more finding: omp rewrites skill descriptions with a model call and caches the result, so what omp sends is a compressed form of the description.

## 2. The spec (`garden/docs/SPEC.md`, seeds format 1.0)
`garden/docs/SPEC.md` is normative; this section records the choices behind it.

### 2.1 Fixed names
- **`SKILL.md` only at the root.** opencode registers any nested `SKILL.md` as another skill. On a case-insensitive filesystem (Windows drives under `/mnt/c`, macOS) `skill.md` *is* `SKILL.md`, so the ban covers every casing.
- **Upper-case names are files the machinery reads by name:** `SKILL.md`, `ENTRY.md`, `SEED.md`, `MEMORY.md`, `INDEX.md`. Lower-case names are content (`docs/testing.md`, `memory/runs.md`, `workflow.md`).
- **No `.git`, worktree or clone below the root** other than the root's own `.git`: opencode scans dot folders, and a staged copy would carry a second `SKILL.md`. Staging happens outside the repo (§4.5).
- **Every path is relative to the root**, including inside an `ENTRY.md` (0014 made those relative to the skill's folder; one base is simpler, and shared skills mostly name root files). A bare file name inside a skill folder names the file beside it, which is how vendored skills already work. Every tool tells the model the skill's folder (Claude Code and opencode print "Base directory for this skill"; pi and omp give the path of the `SKILL.md` they read). A symlink resolves to the clone, so `git -C <root>` works.

### 2.2 Root `SKILL.md` (the router)
```yaml
---
name: garden
description: "Your bots (seeds) for software work. Routes every task (feature, fix, refactor, review, docs, chores, questions about code) to the seed that fits, with its rules and memory, or handles a one-off directly. Use when starting any software task, before acting on it."
metadata:
  seeds-format: "1.0"
  version: "1.0.0"
---
```
- Agent Skills fields only; never `disable-model-invocation`. `name` is fixed: `garden` in every copy, so upstream updates never conflict on it.
- The description is at most 1024 characters and contains "Use when". The body is at most 600 words: called seeds; read first; route; hand over; one-off; changes to the garden.

### 2.3 `seeds/<name>/SEED.md`
```yaml
---
name: reviewer                       # = folder name: lowercase, digits, single hyphens, ≤ 64 characters
when: "Reviewing a pull request or diff for correctness and style before merge."   # ≤ 200 characters
group: code                          # optional; required once there are more than 20 seeds
skills:                              # optional; memory and rsi are implicit and never listed
  required: [escalate, installed:gh-pr-review]
  optional: [handoff, lint-rules]
calls: [coder]                       # optional: seeds it may call or pass to (needs handoff)
access: read-only                    # optional: read-only | edit | full (default full); enforced when CALLED (§6)
autonomy: stop-and-record            # required when escalate is not in skills
---
```
- A bare skill name is a shared skill or one bundled in the seed; a bundled name may not shadow a shared one. `installed:<s>` is a skill the tool discovers itself.
- **`workflow.md`** is optional and free-form. The validator only checks that SEED.md links it, and that each `seed:<name>` it names exists and is in `calls`.
- Vendoring a third-party skill copies it into `skills/<s>/` (the owner's, at the root) or `seeds/<x>/skills/<s>/`, renames `SKILL.md` to `ENTRY.md`, keeps its LICENSE, and records `metadata: {source, commit}`.

### 2.4 Memory, runs and docs formats
Unchanged from 0014 §2.5, renamed: MEMORY.md is Orca's format (`- YYYY-MM-DD <fact>` with an optional ` · from: <seed>`, details in `memory/<topic>.md`, retired lines in `memory/archive.md`), ordered most valuable first and written only through the promotion gate (§13); `seeds/<name>/memory/runs.md` holds one line per run (`date time | task | outcome | tags | note`); `memory/unrouted.md` logs one-off tasks; `docs/INDEX.md` lists every doc as `- [<file>](<file>): read when <condition>.` A seed's docs override the root's. The tag `viol` now counts **access** violations.

### 2.5 Budgets
As 0014 §2.7, enforced by the validator: router description ≤ 1024 characters and body ≤ 600 words; ENTRY.md body ≤ 800 words, supporting file ≤ 300 lines; SEED.md body ≤ 500 words, `when` ≤ 200 characters; `workflow.md` ≤ 800 words; a doc ≤ 1,500 words; an INDEX ≤ 40 entries of ≤ 160 characters; a `seeds/INDEX.md` line ≤ 220 characters; MEMORY.md ≤ 60 lines of ≤ 400 characters; a topic file ≤ 300 lines; `runs.md` and `unrouted.md` ≤ 200 lines. rsi tunes them by root PR.

## 3. The hand-over sequence (in the router, once for every seed)
1. **Start memory:** read `garden/skills/garden-memory/SKILL.md`, the root and the seed's MEMORY.md, then both docs indexes.
2. **Become the seed:** read SEED.md, load its required skills, check `autonomy` against `escalate`. If `access` is not `full`, keep to it: at depth 0 that is an instruction the seed follows, not an enforced limit (§6).
3. **Work:** follow SEED.md (and `workflow.md` if it links one). Write memory as you go.
4. **End:** read `garden/skills/rsi/ENTRY.md`, append the run line, run a retro if triggered, commit memory and the stage **locally**, then report. If the seed's text says to sync at the end, read `garden/skills/garden-sync/SKILL.md`.

A **called** seed does the same in its sub-agent, but never re-routes, never commits, and never syncs. With access below `full` it cannot write at all, so it returns its memory lines, run line and proposed changes in its report, and the caller writes them.

## 4. RSI in detail
Unchanged from 0014 §4 except where pushing was involved:
- **Per run:** one run line and new facts in memory. Only a direct owner correction is staged at once.
- **Retro triggers:** 5 runs since the last retro; the same signal on 2 runs (`esc>0`, `fixes>0`, `viol>0`, `failed`/`stopped`, the same `skipped` skill); a file at 80 % of its budget; the owner asks.
- **Retro checks** (adapted from mattpocock's `retro`): navigation, automated checks (proposed for the project repo, never owned), standards, always-loaded text, tool economy, information access, routing, calls (including access violations), autonomy, memory hygiene, sprawl, a mandatory removal pass, and rsi itself.
- **Compaction:** due at 80 % of a budget; at 100 % memory writes fail (§13). Memory is compacted directly; docs and SEED.md compaction is staged.
- **4.5 The stage:** one git worktree per task and tier, outside the repo and every skills dir: `${XDG_STATE_HOME:-$HOME/.local/state}/garden/<repo>/stage/<YYYYMMDD-HHMM>-<task>-<tier>`, branch `garden/<YYYYMMDD-HHMM>-<task>-<tier>`, tier `seeds` or `root`. A path in `garden/docs/upstream-paths.txt` belongs to the root tier; anything else under `seeds/` and `docs/` to the seeds tier; memory is never staged.
- **4.6 The finish (changed):** at the end of the depth-0 run, rsi runs the validator on the stage, **commits it locally** with the PR title and body as the commit message, and removes the worktree. The branch stays. rsi never pushes and never opens a PR: `sync` does that.
- **Guardrails:** evidence or nothing; at most 5 changes per retro branch; budgets fail CI; owner decisions stick (a declined proposal goes to `memory/rejected.md`, which rsi reads before proposing); rules in memory move to docs; rsi never changes which skills are mandatory, never merges and never pushes.

## 5. Shared skill contracts
### 5.1 `memory` (mandatory)
Reads root and seed MEMORY.md and topic files on demand; writes in the live clone, always through `write.py` and its promotion gate (§13); called seeds write their own seed's memory only when their access allows it, otherwise they return the lines. **At the end of a depth-0 run, memory commits locally:** `git add -- MEMORY.md memory 'seeds/*/MEMORY.md' 'seeds/*/memory'` and `git commit -m "memory: <task>"`. It never pulls or pushes. `.gitattributes` sets `merge=union` on MEMORY.md, `runs.md` and `unrouted.md`. A read-only install (`npx skills add`) writes nothing: memory lines go into the report under `## Memory (not saved)`.

### 5.2 `rsi` (mandatory)
Records the run, runs retros, compacts and stages (§4). Files: `ENTRY.md`, `retro.md`, `stage.md`. It may hand to `new-seed` to propose or retire a seed.

### 5.3 `escalate` (optional)
When to ask (unclear and changes the outcome; irreversible or visible to others; against a doc rule; stuck after 2 tries; scope grew), otherwise decide and record. The fixed `<<<SEED … >>>` block is built by `garden/skills/garden-escalate/block.sh` (kinds `escalation`, `review`, `question`, `route`), which refuses an empty field, more than one `?`, or more than 4 options. The report format: `## Done`, `## Decided alone`, `## Escalated`, `## Open`, `## Memory`, `## Staged`. A seed without escalate has an `autonomy` fallback: `decide-and-record` (safest reversible option; never irreversible or outward actions) or `stop-and-record`.

### 5.4 `handoff` (optional, with `calls`)
**Call** a seed as a fresh sub-agent and use its result, or **pass** it the task and finish. Guards: the target is in `calls`, no seed twice in the chain, depth ≤ 3, a called seed never re-routes. How a call starts depends on the target's `access` (§6). A **pass** continues in the same session, so it cannot enforce access: passing to a seed whose access is not `full` is refused (call it instead).

### 5.5 `sync` (optional; new: replaces every push in 0014)
Runs **only** where a seed's text says to, or when the owner asks; never automatically, never from rsi or memory. new-seed offers it when building a seed. In order:
1. **Pull origin, fast-forward only, keeping local memory.** `git fetch origin`. If the branch is behind, `git merge --ff-only`. If it has diverged and every local-only commit touches memory paths only, `git rebase` them onto origin (the `merge=union` driver keeps both sides' lines). Anything else stops and reports; sync never makes a merge commit on the default branch and never force-pushes.
2. **Push local memory** to the default branch: only when every commit ahead of origin touches memory paths only.
3. **Push staged behaviour** as PRs, per rsi tier: each local `garden/*` branch is pushed and gets `gh pr create --fill` (title and body from rsi's commit). One PR per branch, so the seeds and root tiers stay separate.
4. **Pull upstream (garden).** `git fetch upstream --tags`; take the newest `v1.*` tag. If the default branch is an ancestor of it, fast-forward. Otherwise (the usual case, since a used garden has its own commits) the release becomes a **root-tier PR**: a stage worktree merges the tag on a `garden/<date>-upstream-<tag>-root` branch, the validator runs, and the branch is pushed as `root: garden <tag>`. That merge happens on the PR branch only; the owner merges the PR.
5. **Record decisions:** each `garden/*` PR closed unmerged goes to `memory/rejected.md` (§13).
- **Never merges** a PR, never runs on its own, and without `origin` or `gh` says what it would have done.

### 5.6 `new-seed`
Builds, changes or retires a seed with the owner, one question per message (escalate's block, kind `question`, recommendation first). Topics: purpose; `when`; what it reads; skills; calls (and optionally `workflow.md`); `access`; escalate or autonomy; whether it syncs (offering `sync`); seed memory. Examples marked "example, not required": a `task-manager` that calls `planner`, `coder` and `reviewer`, and a lone read-only `reviewer`. Builds in the seeds-tier stage.

## 6. Access levels (new)
`access` in SEED.md frontmatter: `read-only` (no edit, no shell), `edit` (file edits, no shell), `full` (everything; the default). It limits a seed **when it is called** through handoff.
- **Read-only and edit** calls run the target as a fresh, non-interactive session of the same tool with a tool allowlist: `bash garden/skills/garden-handoff/call.sh <tool> <access> <prompt-file>`. The tool itself enforces the limit.
- **Full** calls use the tool's in-session sub-agent (Claude Code's Agent tool, opencode's and omp's `task` tool; pi has none and uses `call.sh pi full`).
- **Backstop:** before every call, `garden/skills/garden-handoff/check.sh snapshot` records HEAD, refs and a tree of the working directory (untracked files included) through a temporary index, so it touches nothing; after it, `check.sh verify <access> <token>` fails on any change for read-only, and on a commit or ref change (only a shell can do that) for edit. For access below `full` the garden root is snapshotted too and must not change at all.
- **The garden is outside the working directory:** a called seed reads its SEED.md, docs and memory there while it works in a project. `call.sh` grants that read explicitly where a tool limits paths.

Proven by `garden/dev/prove-access.sh` against a scripted fake model in a temp HOME (2026-11-23): for each tool and level it compares the tools offered in the request with the allowlist, then has the model call the write tool, the shell, and the read tool on a file outside the working directory, including tools that were not offered.

| | read-only | edit | outside the working directory | how |
|---|---|---|---|---|
| Claude Code 2.1.330 | **enforced**: offers Read, Grep, Glob; Write and Bash refused ("No such tool available") | **enforced**: adds Edit, Write; Bash refused | `-p` refuses it, so `call.sh` adds a `Read(/<garden>/**)` allow rule: the garden is readable, writes outside are refused | `claude -p --tools … --strict-mcp-config --permission-mode dontAsk` (edit: `acceptEdits`) `--settings …` |
| pi 0.80.2 | **enforced**: offers read, grep, find, ls | **enforced**: adds edit, write | no limit: reads and (edit) writes anywhere | `pi -p --no-session --tools …` |
| omp 18.11 | **enforced**: offers read, grep, glob | **enforced**: adds edit, write | no limit: reads and (edit) writes anywhere | `omp -p --no-session --no-lsp --tools …` |
| opencode 1.18.30 | **enforced**: offers read, grep, glob | **enforced**: adds edit, write | `external_directory` allows the garden only; at edit level it is writable too (edit patterns did not narrow it) | `opencode run --agent garden-<level>`, the agent's `permission` (`"*": "deny"`, an allowlist, `external_directory`) in `OPENCODE_CONFIG_CONTENT` |

`--approval-mode` (omp) and `--agents` (Claude Code) turned out unnecessary: `--tools` already removes the tools, and a `-p` run cannot answer prompts anyway. What stays **only checked afterwards**: any in-session fallback (Claude Code's Explore and Plan agents drop Edit/Write but keep Bash; `task` sub-agents have no per-call tool list); a `full` call (nothing to enforce); at edit level, *which* files changed; and for pi, omp and opencode, edit-level writes outside the working directory (the garden snapshot catches writes to the garden; writes elsewhere are not seen).

## 7. Upstream (noueii/garden → a user's garden)
- **Creating a garden:** clone noueii/garden, `git remote rename origin upstream`, then `gh repo create <you>/garden --private --source . --push`. A GitHub fork works too, but a fork of a public repo is public, and so would be your memory.
- **Ownership:** `garden/docs/upstream-paths.txt` lists what upstream owns: since 0002, `SKILL.md`, `garden/`, `.github/workflows/garden.yml` and `.gitattributes`. The user owns everything else: `docs/`, `seeds/`, `skills/`, `MEMORY.md`, `memory/`, and the root `README.md`, `AGENTS.md` and `CLAUDE.md`.
- **No conflicts by construction:** upstream's copies of user-owned paths are placeholders, frozen by hash (`garden/dev/check-upstream.sh`), so an upstream release never touches the user's files. A conflict is only possible in a root file the user changed through a root PR.
- **The update** is `sync` step 4 (§5.5). A major format bump (`seeds-format: 2.x`) ships a `garden/docs/MIGRATING.md` section, and the update PR migrates user-owned files too.

## 8. Install
```sh
git clone git@github.com:you/garden.git ~/src/garden
ln -s ~/src/garden ~/.agents/skills/garden      # opencode, pi, omp
ln -s ~/src/garden ~/.claude/skills/garden      # Claude Code (omp and opencode dedupe by real path)
```
- **`npx skills add you/garden -g`** is a read-only trial: a copy without git, so memory and rsi save nothing.
- **The optional global line**, added by the owner by hand: "Start every task with the `garden` skill, unless your prompt says you were called as a seed inside a running task."

## 9. Orca
An Orca bot hosts a seed with a one-paragraph SOUL.md ("You are seed `<name>`. Follow `<root>/seeds/<name>/SEED.md`, starting with the hand-over sequence in `<root>/SKILL.md`; skip routing."). The bot's `MEMORY.md` and `memory/` can be symlinks to the seed's. Nothing in the repo depends on Orca.

## 10. Checks
- **`garden/check/validate.py <repo>`** (python3 + PyYAML; ships; the user's CI runs it), structural only: layout (one SKILL.md in any casing, no nested `.git`, required files, flat docs), frontmatter (keys, names, `access` values, `autonomy` iff no escalate, `calls` needs handoff), references (skills, calls, `seed:` names, Markdown links inside the root), indexes (both ways), memory line formats, budgets.
- **`--upstream`** (`garden/dev/check-upstream.sh`, garden only): placeholders unchanged by hash, no seeds, no docs, empty memory.
- **Negative fixtures** in `garden/dev/fixtures/` are shell overlays applied to a temp copy, so garden stores no second SKILL.md.
- **Script tests** (`garden/dev/test-scripts.sh`, in CI): `block.sh`, `call.sh` (dry run), `check.sh` and `sync.sh` in temp repos.
- **`garden/dev/prove-access.sh`** (§6) and **`garden/dev/prove-install.sh`** (pi and omp list exactly `garden`; opencode and Claude Code send `garden` and no internal name to a fake model; a nested seed, bundled skill and vendored ENTRY.md add nothing; the global line reaches the request; an update reaches the next request). Both need the tools installed, so they run on a maintainer's machine, not in CI.

## 11. Delivery
One PR on noueii/garden (the owner asked for one PR rather than a stack), with one commit per part:
1. this ADR;
2. the spec: `garden/docs/SPEC.md`, `garden/docs/upstream-paths.txt`, the router `SKILL.md` and the empty placeholders;
3. the validator and CI: `garden/check/validate.py`, `garden/dev/fixtures/`, `garden/dev/check-upstream.sh`, `.github/workflows/garden.yml`;
4. memory, rsi and sync, plus `.gitattributes`;
5. escalate and handoff with access levels (`block.sh`, `call.sh`, `check.sh`, `garden/dev/prove-access.sh`);
6. new-seed: the interview, the examples, vendoring;
7. memory safety (§13): `write.py`, lessons and rejected files, hard budgets, `garden/check/pre-commit.sh`;
8. the install proof: `garden/dev/prove-install.sh`;
9. the guide and README: `guide/` (now `garden/docs/`), README, AGENTS.md, CLAUDE.md, `garden/dev/AGENTS.md`.

## 12. Decisions
1. **"seed"** (owner, overriding 0014's recommendation of "bot").
2. **The skill is named `garden`, fixed in every copy.** The Agent Skills spec and opencode require `name` to equal the folder name, and the installed folder (the symlink) is named after the repo. "seeds" would name the folder of seeds inside it. Fixed, so upstream updates never conflict on it.
3. **Access levels** replace `may_change` (owner), enforced as in §6. Two consequences decided here: a `pass` to a seed with access below `full` is refused (it can't be enforced in the same session), and a called seed that can't write returns its memory and run lines for the caller to write.
4. **Memory commits locally; sync pushes** (owner). Upstream releases arrive as root PRs, because a used garden can't fast-forward to them (§5.5 step 4).
5. **The router reads `seeds/INDEX.md`** (owner, Q5); SEED.md stays the source of truth and the validator keeps them equal.
6. **Clone + symlink is the documented install** (owner, Q6); `npx skills add` gets one line as a read-only trial.
7. **Maintainer files in `dev/` (now `garden/dev/`), shipped inert** (owner, Q7).
8. **No LICENSE** for now (owner); the README says it's undecided.

## 13. Memory safety (owner-approved addition, 2026-11-23)
From research on agent memory (Letta Code's MemFS, OpenClaw's promotion gates, Hermes Agent's hard caps), the owner approved one bundle. All of it goes through one script, `garden/skills/garden-memory/write.py`, which every memory write uses; its formats and budgets come from `garden/check/validate.py`, so there is one table.
1. **Promotion gate.** A new lesson lands in `memory/lessons.md` (root or seed) with `· seen: <run>`. It moves into MEMORY.md only once 2 runs saw it, or when the owner states it directly (`--owner`). write.py refuses any other MEMORY.md write.
2. **Untrusted text is never promoted.** Tool output, web pages, issue text and called seeds' reports become memory only once verified; a caller writes what a called seed returned as lessons. Before any write, write.py refuses instruction-like text (including "always"/"never" rules, which go to docs), secrets and tokens, and invisible or control characters, and says why; the run line counts refusals (`refused=`).
3. **Hard budgets.** In the spec table (`garden/docs/SPEC.md` §7). Compaction is due at 80 %; at 100 % a write fails loudly (nothing truncated, no warning-and-continue), so rsi compacts or removes first. The validator fails any file over budget in CI, and the optional `garden/check/pre-commit.sh` does it locally. MEMORY.md is ordered most valuable first, because tools may load only the start of a long file.
4. **Rejected list.** Proposals the owner declines (in conversation, or a `garden/*` PR closed unmerged, which sync records) go to `memory/rejected.md`, one line each (date, proposal, reason). rsi reads it before proposing anything.

Not adopted: IDs or counters on memory lines, before/after run comparisons, failing-fixture proofs for checks, and changes to the sync merge rule.
