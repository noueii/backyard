# garden

Your coding bots, in one git repo that your AI tools load as **one skill**.

A **seed** is a bot with one purpose: a reviewer, a planner, a task manager that runs the other two. Each seed is a short `SEED.md` in plain prose, with its own docs and memory. Your **garden** is the repo that holds them, and its root folder is the only skill Claude Code, opencode, pi and omp see. Its router picks the seed that fits each task. Seeds call each other, remember what they learn, and propose improvements to themselves from evidence, which you review.

- **One skill per tool.** Shared skills inside are `ENTRY.md` files that no tool discovers, so nothing collides with your other skills.
- **Seeds compose.** No roles and no workflow engine: a seed that runs others says so in your own words.
- **Memory stays local.** Facts are committed to your clone and pushed only when you ask (`sync`). Every write goes through a gate that refuses secrets, hidden characters and instruction-like text, and only promotes a lesson once two runs saw it, or you stated it.
- **Self-improvement by branch.** After runs and retros, `rsi` stages evidence-backed changes on local branches; `sync` opens them as pull requests. Nothing is ever merged for you.
- **Access levels.** `access: read-only | edit | full` on a seed; when another seed calls it, your tool enforces it.
- **No runtime.** No plugins, CLI, hooks or AI evals: Markdown, a few small scripts, and a structural validator.

## Install
Make your own private copy, then link it into your tools:
```sh
git clone https://github.com/noueii/garden.git ~/src/garden
cd ~/src/garden && git remote rename origin upstream
gh repo create <you>/garden --private --source . --push   # optional: your origin

mkdir -p ~/.agents/skills ~/.claude/skills
ln -s ~/src/garden ~/.agents/skills/garden     # opencode, pi, omp
ln -s ~/src/garden ~/.claude/skills/garden     # Claude Code
```
**Update:** ask your tool to "sync the garden" (`skills/sync/`), or `git -C ~/src/garden pull --rebase`.

`npx skills add noueii/garden -g` also works, as a **read-only trial**: a copy without git, so memory and self-improvement save nothing.

Then follow [the tutorial](guide/tutorial.md): your first seed, a second one that calls it, retros, and sync.

## What's inside
| | |
|---|---|
| `SKILL.md` | the router |
| `skills/` | memory, rsi (mandatory); escalate, handoff, sync, new-seed (optional) |
| `seeds/`, `docs/`, `MEMORY.md`, `memory/` | yours: empty here |
| [`spec/SPEC.md`](spec/SPEC.md) | the seeds format |
| `check/validate.py` | the structural validator (your CI runs it) |
| [`guide/`](guide/tutorial.md) | the tutorial and a reference |
| `dev/` | maintainer files: [decisions](dev/decisions/0001-seeds.md), fixtures, proofs |

Tested with Claude Code 2.1.330, opencode 1.18.30, pi 0.80.2 and omp 18.11 (`dev/prove-install.sh`, `dev/prove-access.sh`, no AI involved).

## License
**Undecided.** There is no LICENSE file yet, so no license is granted for now. The owner will choose one.

## Credits
garden grew out of [noueii/psai](https://github.com/noueii/psai): its ADRs 0013 (the tool-discovery research) and 0014 (the plan), and psai 4.0's escalation block and test helpers.
