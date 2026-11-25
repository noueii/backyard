# expect: ok
# A small, valid backyard: two seeds that compose (task-manager calls reviewer through backyard-handoff, with a workflow.md),
# a bundled skill, a vendored skill, docs on both levels, and memory: committed, pending and rejected, shared and per seed. Other fixtures source
# this file and then break one thing. Runs in a temp copy of the repo (backyard/dev/test-validate.sh).
set -e
mkdir -p seeds/reviewer/docs seeds/reviewer/memory/committed seeds/task-manager/docs seeds/task-manager/memory/committed \
  seeds/task-manager/memory/pending seeds/task-manager/skills/plan-format seeds/reviewer/skills/tdd memory/committed memory/pending docs

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
cat > seeds/reviewer/skills/tdd/SKILL.md <<'EOF'
---
name: tdd
description: "Test-driven development, vendored."
metadata: { source: "github:example/skills/tdd", commit: "0123456789abcdef0123456789abcdef01234567" }
---
Red, green, refactor.
EOF
printf '# Docs\n\n- [style.md](style.md): read when judging naming or layout.\n' > seeds/reviewer/docs/INDEX.md
printf '# Style\n\nPrefer small functions.\n' > seeds/reviewer/docs/style.md
INTRO='One line per committed memory, most valuable first: tools may load only the start. Open a file only when its line fits the task.'
mem() { # <file> <type> <source> <seen or -> <body>
  { printf -- "---\ntype: %s\ndate: %s\nsource: '%s'\n" "$2" "$(basename "$1" | cut -c1-10)" "$(printf '%s' "$3" | sed "s/'/''/g")"
    [ "$4" = - ] || printf 'seen: [%s]\n' "$4"; printf -- '---\n%s\n' "$5"; } > "$1"
}
idx() { # <memory folder> <file> <condition>: add an INDEX.md line
  [ -f "$1/INDEX.md" ] || printf '# Memory\n\n%s\n' "$INTRO" > "$1/INDEX.md"
  printf -- '- [%s](committed/%s): read when %s.\n' "$2" "$2" "$3" >> "$1/INDEX.md"
}
mem seeds/reviewer/memory/committed/2026-11-23-app-has-no-formatter.md fact 'owner: "the app repo has no formatter"' - \
  'The app repo has no formatter configured, so style findings are judgement calls.'
idx seeds/reviewer/memory 2026-11-23-app-has-no-formatter.md 'judging style in the app repo'

cat > seeds/task-manager/SEED.md <<'EOF'
---
name: task-manager
when: "Taking a feature or fix from request to reviewed change: plans, implements, then gets it reviewed."
skills:
  required: [backyard-escalate, backyard-handoff, plan-format]
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
cat > seeds/task-manager/skills/plan-format/SKILL.md <<'EOF'
---
name: plan-format
description: "The owner's plan format. Use when writing a plan."
---
Goal, steps, risks. See [the example](example.md).
EOF
printf '# Example\n\nGoal: x. Steps: y. Risks: z.\n' > seeds/task-manager/skills/plan-format/example.md
printf '# Docs\n\n' > seeds/task-manager/docs/INDEX.md
mem seeds/task-manager/memory/committed/2026-11-23-api-plans-need-migration-step.md lesson \
  'login-fix: the reviewer flagged a missing migration' 'login-fix, add-search' \
  'Plans for the api repo need a migration step: its migrations live in db/migrate and CI fails without them.'
idx seeds/task-manager/memory 2026-11-23-api-plans-need-migration-step.md 'planning a change to the api repo'
mem seeds/task-manager/memory/pending/2026-11-24-reviewer-slow-on-large-diffs.md lesson \
  'add-search: the reviewer call took 9 minutes on a 2,000-line diff' add-search \
  'The reviewer is slow on diffs over a thousand lines; splitting the diff may help.'

printf '# Seeds\n\n- reviewer: Reviewing a pull request or diff for correctness and style before merge.\n- task-manager: Taking a feature or fix from request to reviewed change: plans, implements, then gets it reviewed.\n' > seeds/INDEX.md
printf '# Docs\n\n- [testing.md](testing.md): read when writing or changing tests.\n' > docs/INDEX.md
printf '# Testing\n\nName tests after the behaviour.\n' > docs/testing.md
printf '# Memory\n\n%s\n' "$INTRO" > memory/INDEX.md
mem memory/committed/2026-11-23-owner-uses-two-wsl-distros.md fact 'owner: "I work in two WSL distros, work and personal"' - \
  'The owner works in two WSL distros, work and personal: each has its own backyard.'
idx memory 2026-11-23-owner-uses-two-wsl-distros.md 'setting up tools or paths'
mem memory/pending/2026-11-23-no-seed-for-git-chores.md lesson 'rename-branch: a git chore no seed fit' rename-branch \
  'A git chore (renaming a branch) had no seed; a second one would make a chores seed worth proposing.'
printf '# Rejected\n\nProposals the owner declined. Read before proposing a change; never re-propose one without new evidence.\n- 2026-11-23 | seeds(reviewer): run the linter first | the owner prefers CI to do it\n' > memory/rejected.md
