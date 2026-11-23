# expect: garden's sync skill is renamed garden-sync
# A half-done migration: a 2.x garden skill folder left next to its renamed one.
. "$FIXTURES/good-seeds.sh"
mkdir -p garden/skills/sync && cp garden/skills/garden-sync/SKILL.md garden/skills/sync/SKILL.md
