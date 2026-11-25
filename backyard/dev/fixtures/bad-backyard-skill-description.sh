# expect: a backyard skill's description starts with "Part of the backyard skill"
# Without it, a tool that lists nested skills (opencode) offers backyard-sync as if it stood on its own.
. "$FIXTURES/good-seeds.sh"
sed -i '3s/Part of the backyard skill, used through its router and seeds, never on its own. //' backyard/skills/backyard-sync/SKILL.md
