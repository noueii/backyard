# expect: ok
# A small, valid garden: two seeds that compose (task-manager calls reviewer through handoff, with a workflow.md),
# a bundled skill, a vendored skill, docs on both levels, memory, runs and unrouted lines. Other fixtures source
# this file and then break one thing. Runs in a temp copy of the repo (dev/test-validate.sh).
set -e
stub() { # <dir> <name>: a shared skill, only if the repo doesn't have it yet
  [ -f "$1/ENTRY.md" ] && return 0
  mkdir -p "$1"
  printf -- '---\nname: %s\ndescription: "Stub for the fixture. Use when testing."\n---\nStub.\n' "$2" > "$1/ENTRY.md"
}
for s in memory rsi escalate handoff; do stub "skills/$s" "$s"; done

mkdir -p seeds/reviewer/docs seeds/reviewer/memory seeds/task-manager/docs seeds/task-manager/memory \
  seeds/task-manager/skills/plan-format seeds/reviewer/skills/tdd memory docs

cat > seeds/reviewer/SEED.md <<'EOF'
---
name: reviewer
when: "Reviewing a pull request or diff for correctness and style before merge."
skills:
  optional: [tdd, installed:gh-pr-review]
access: read-only
autonomy: stop-and-record
---
You are the reviewer. You review diffs and report findings; you never change code.
Read the diff, check it against `docs/INDEX.md`, and list findings by severity.
Done when: every changed file is reviewed. Never: edit files.
EOF
cat > seeds/reviewer/skills/tdd/ENTRY.md <<'EOF'
---
name: tdd
description: "Test-driven development, vendored."
metadata: { source: "github:example/skills/tdd", commit: "0123456789abcdef0123456789abcdef01234567" }
---
Red, green, refactor.
EOF
printf '# Docs\n\n- [style.md](style.md): read when judging naming or layout.\n' > seeds/reviewer/docs/INDEX.md
printf '# Style\n\nPrefer small functions.\n' > seeds/reviewer/docs/style.md
printf '# Memory\n\nOne line per fact, most valuable first: tools may load only the start. Longer notes go in memory/<topic>.md.\n- 2026-11-23 The app repo has no formatter configured. · from: reviewer\n' > seeds/reviewer/MEMORY.md
printf '# Runs\n\n- 2026-11-23 14:05 | review-login | done | repo=you/app caller=task-manager | 2 findings\n' > seeds/reviewer/memory/runs.md

cat > seeds/task-manager/SEED.md <<'EOF'
---
name: task-manager
when: "Taking a feature or fix from request to reviewed change: plans, implements, then gets it reviewed."
skills:
  required: [escalate, handoff, plan-format]
calls: [reviewer]
---
You are the task manager. Follow [workflow.md](workflow.md).
Done when: the reviewer has no blocking findings. Never: merge.
EOF
cat > seeds/task-manager/workflow.md <<'EOF'
# Workflow
1. Plan with the plan-format skill.
2. Implement.
3. Call `seed:reviewer`. If it asks for changes, fix and call it again, at most twice, then stop and record.
EOF
cat > seeds/task-manager/skills/plan-format/ENTRY.md <<'EOF'
---
name: plan-format
description: "The owner's plan format. Use when writing a plan."
---
Goal, steps, risks. See [the example](example.md).
EOF
printf '# Example\n\nGoal: x. Steps: y. Risks: z.\n' > seeds/task-manager/skills/plan-format/example.md
printf '# Docs\n\n' > seeds/task-manager/docs/INDEX.md
printf '# Memory\n\nOne line per fact, most valuable first: tools may load only the start. Longer notes go in memory/<topic>.md.\n- 2026-11-23 Plans for the api repo need a migration step. Details in memory/api.md.\n' > seeds/task-manager/MEMORY.md
printf '# Api\n\nMigrations live in db/migrate.\n' > seeds/task-manager/memory/api.md
printf '# Runs\n\n- 2026-11-23 14:00 | login-fix | done | calls=reviewer esc=0 fixes=1 | owner corrected the redirect\n- 2026-11-24 09:12 | retro | 6 runs | branch=garden/20261124-0912-retro-seeds root=- |\n' > seeds/task-manager/memory/runs.md

printf '# Seeds\n\n- reviewer: Reviewing a pull request or diff for correctness and style before merge.\n- task-manager: Taking a feature or fix from request to reviewed change: plans, implements, then gets it reviewed.\n' > seeds/INDEX.md
printf '# Docs\n\n- [testing.md](testing.md): read when writing or changing tests.\n' > docs/INDEX.md
printf '# Testing\n\nName tests after the behaviour.\n' > docs/testing.md
printf '# Memory\n\nOne line per fact, most valuable first: tools may load only the start. Longer notes go in memory/<topic>.md.\n- 2026-11-23 The owner works in two WSL distros, work and personal.\n' > MEMORY.md
printf '# Unrouted\n\n- 2026-11-23 10:00 | rename-branch | one-off | repo=you/app | a git chore, no seed needed\n' > memory/unrouted.md
