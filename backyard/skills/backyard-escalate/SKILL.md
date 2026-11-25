---
name: backyard-escalate
description: "Part of the backyard skill, used through its router and seeds, never on its own. When and how a seed asks the owner, the fixed question block, and the format of a seed's final report. Use when a seed that lists backyard-escalate must ask or is finishing, and when the router asks about a routing tie or a new seed."
metadata: { seeds-format: "2.0" }
---
# escalate

Paths are relative to the backyard root.

## When to ask
Ask the owner only when one of these holds:
- the task is unclear **and** the answer changes the outcome;
- the next step is irreversible or visible to others (push to a shared branch, delete, deploy, post, spend);
- it goes against a rule in the docs;
- you are stuck after 2 tries;
- the scope grew beyond what was asked.

Otherwise **decide**, and record the decision and its reason in the report (`## Decided alone`) and, if it will matter again, in memory. Read docs and memory before asking: never ask what they already answer.

## How to ask: the fixed block
Build it with the script, never by hand:
```sh
bash backyard/skills/backyard-escalate/block.sh --kind escalation --seed <name> \
  --question "<one question>" --why "<why docs and memory can't settle it>" \
  --option "<your recommendation>" --option "<another>"
```
- `--kind`: `escalation` (you can't or mustn't decide alone), `review` (asking for approval or changes), `question` (new-seed's interview), `route` (the router's tie).
- `--seed`: the asking seed; `backyard` when the router asks.
- One question only; at most 4 options, your recommendation first. The script refuses anything else: fix the call, don't work around it.

Put the block at the **end** of your message and stop. The owner's next message is the answer: resume where you asked. One block per message.

A **called** seed never asks the owner directly: it ends with the block in its report, and its caller asks (or decides, under its own rules) and calls it again with the answer.

## The report
End every run of a seed that uses escalate with these sections, leaving out empty ones:
- `## Done`: what was done, with links (PRs, commits, files).
- `## Decided alone`: each decision and its reason.
- `## Escalated`: what you asked and the answer, or the open block.
- `## Open`: what is left, and who has it.
- `## Memory`: lines written (or `## Memory (not saved)`: lines to write, each with its file).
- `## Staged`: local `backyard/*` branches staged by memory or new-seed, and whether sync opened PRs for them.

A **handover note** (handoff's pass) uses the same sections plus `## State` (repo, branch, worktree, last commit) and `## Next` (the first step for whoever continues).

## Seeds without escalate
They never ask mid-task. Their `autonomy` decides what happens when one of the "when to ask" cases comes up:
- **`decide-and-record`:** take the safest **reversible** option, record it in the report and, if it will matter again, as a pending memory (type `decision`), and go on. Irreversible or outward actions are never decided: they stop as below.
- **`stop-and-record`:** stop, leave the work on a branch or worktree, record what blocks it in the report (and as a pending memory if the next run should know), and end.

The router may always ask about a routing tie or a new-seed offer with this block: routing happens before any seed runs.
