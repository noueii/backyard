# expect: a skill's file is SKILL.md since garden 3.0.0
# A half-done migration: a 2.x ENTRY.md beside (or instead of) SKILL.md.
. "$FIXTURES/good-seeds.sh"
cp seeds/task-manager/skills/plan-format/SKILL.md seeds/task-manager/skills/plan-format/ENTRY.md
