# expect: SKILL.md is only allowed at the root
. "$FIXTURES/good-seeds.sh"
mkdir -p seeds/reviewer/skills/x && printf 'x\n' > seeds/reviewer/skills/x/skill.md
