# expect: backyard's sync skill is renamed backyard-sync
# A half-done migration: a 2.x backyard skill folder left next to its renamed one.
. "$FIXTURES/good-seeds.sh"
mkdir -p backyard/skills/sync && cp backyard/skills/backyard-sync/SKILL.md backyard/skills/sync/SKILL.md
