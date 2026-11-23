# expect: SKILL.md is only allowed at the root
# opencode would register a SKILL.md inside garden/ as a second skill.
. "$FIXTURES/good-seeds.sh"
printf 'x\n' > garden/skills/memory/SKILL.md
