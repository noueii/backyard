# Access levels, per tool

What `call.sh` really enforces, proven by `backyard/dev/prove-access.sh` (2026-11-23) against a scripted fake model: for each tool and level it compares the tools offered with the allowlist, then has the model call the write tool, the shell, and the read tool on a file outside the working directory, including tools that were not offered.

`read-only`: read and search only. `edit`: also edit and write files. Neither has a shell, sub-agents, web or MCP tools. `full`: everything your settings allow.

| tool | how `call.sh` starts it | read-only | edit | outside the working directory |
|---|---|---|---|---|
| Claude Code 2.1.330 | `claude -p --tools <list> --strict-mcp-config --permission-mode dontAsk` (edit: `acceptEdits`), `--settings` allowing `Read` of the backyard | **enforced**: only Read, Grep, Glob; others refused ("No such tool available") | **enforced**: adds Edit, Write | reads the backyard only (allow rule); writes refused |
| pi 0.80.2 | `pi -p --no-session --tools <list>` | **enforced**: read, grep, find, ls | **enforced**: adds edit, write | reads and (edit) writes anywhere |
| omp 18.11 | `omp -p --no-session --no-lsp --tools <list>` | **enforced**: read, grep, glob | **enforced**: adds edit, write | reads and (edit) writes anywhere |
| opencode 1.18.30 | `opencode run --agent backyard-<level>`, the agent in `OPENCODE_CONFIG_CONTENT`: `permission: {"*": "deny", <allowlist>, external_directory: the backyard only}` | **enforced**: read, grep, glob | **enforced**: adds edit, write | the backyard only; (edit) writes there too |

**Only checked afterwards** (by `check.sh`):
- every in-session fallback: nothing limits it per call. (Claude Code's Explore and Plan agent types drop Edit and Write but keep Bash, as Claude Code 2.1.330 lists them; opencode's and omp's `task` tool has no per-call tool list.)
- *which* files an `edit` seed changed (any file in the working directory is allowed), and, for pi, omp and opencode, writes outside it: the backyard snapshot catches writes to the backyard; writes elsewhere are not seen;
- an `edit` seed committing or branching: only a shell can, so a moved HEAD or ref is a violation;
- a `full` call: nothing to enforce; the changes are listed.
