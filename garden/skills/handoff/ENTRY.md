---
name: handoff
description: "Runs another seed: calls it as a fresh sub-agent with its access level enforced and uses its result, or passes it the task and finishes. Use when a seed's SEED.md or workflow.md says to call or pass to another seed."
metadata: { seeds-format: "2.0" }
---
# handoff

Paths are relative to the garden root. Scripts: `garden/skills/handoff/call.sh` (starts a called seed with only the tools its access allows) and `garden/skills/handoff/check.sh` (the git backstop).

## Guards (check before every call or pass)
- The target is in your SEED.md's `calls`.
- No seed twice in the chain (no cycles), and a depth of at most 3 (calls and passes both count).
- A called seed never re-routes the original request.

A guard that refuses goes to your escalate, or your autonomy fallback.

## Call: run a seed and use its result
1. Read the target's `access` (`seeds/<x>/SEED.md`; default `full`).
2. Write the prompt to a file. It starts:
   > You were called as seed `<x>` by seed `<y>`, task `<task>`, chain `<a > y>`, depth `<n>`, stage `<path or ->`, access `<level>`. Do not route this request and do not start other seeds except through handoff. Follow `<root>/seeds/<x>/SEED.md` per the hand-over in `<root>/SKILL.md`, then return your report. Never commit, push or sync. With access `read-only` or `edit`, write no memory and stage nothing: return `## Memory (not saved)` and `## Proposed changes` in your report.

   Then the brief: the goal, the inputs, what to return, and the base commit.
3. **Snapshot** the directory the seed works in: `token="$(bash garden/skills/handoff/check.sh snapshot <dir>)"`. For access below `full`, snapshot the garden root too (`gtoken`): such a seed must not change it at all.
4. **Start it**, by access:
   - `read-only` or `edit`: `bash garden/skills/handoff/call.sh <tool> <access> <prompt file>` from `<dir>`, where `<tool>` is the one you run in: `claude`, `pi`, `omp` or `opencode`. The tool itself enforces the limit (table below). It can take as long as a whole task, so use your shell's longest timeout or run it in the background and wait for it.
   - `full`: your tool's in-session sub-agent, in the foreground: Claude Code's Agent tool (`general-purpose`), opencode's `task` tool (`subagent_type: general`), omp's `task` tool. pi has none: `bash garden/skills/handoff/call.sh pi full <prompt file>`.
   - If `call.sh` can't run (the tool is not on PATH, or it fails to start), fall back to the in-session sub-agent, say the limits in the prompt, and rely on the backstop. Note the fallback in your report.
5. **Check** after it returns: `bash garden/skills/handoff/check.sh verify <access> "$token" <dir>`, and for access below `full` also `bash garden/skills/handoff/check.sh verify read-only "$gtoken" <garden root>`.
   - exit 0: use the result.
   - exit 1 (**violation**): don't use the changes. Show them in your report, capture it as a pending memory of the called seed (a failure; `garden/skills/memory/ENTRY.md`), and escalate or stop per your autonomy. Don't call it again with the same brief.
6. Write what it returned: run its `## Memory (not saved)` commands as pending memories (`--seen <its task>`), and put its proposed changes into your stage (`garden/skills/memory/stage.md`), with their evidence.

A called seed's open escalation block comes back in its report: ask the owner yourself (or decide, under your own rules), then call it again with the answer.

## Access levels
`read-only`: read and search only. `edit`: also edit and write files. Neither has a shell, sub-agents, web or MCP tools. `full`: everything your settings allow. Through `call.sh` every tool **enforces** read-only and edit; what each one allows outside the working directory, and what is only checked afterwards, is in `garden/skills/handoff/access.md`.

## Pass: give a seed the task and finish
1. The target's `access` must be `full`: a pass continues in this session, where nothing can be enforced. Otherwise call it instead.
2. Write the handover note (escalate's report format with `## State` and `## Next`, or the same sections inline).
3. Continue in this session as the target, from step 1 of the hand-over in `SKILL.md`.

A seed hosted by another Orca bot is passed by messaging that bot the note instead.

## Every called seed runs its own memory
So each seed improves on its own; only depth 0 runs retros, commits memory, finishes stages, and (when told to) syncs.
