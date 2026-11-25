# expect: a SKILL.md is allowed only at the root and as a skill's own file
# A SKILL.md that is not a skill's own file (here in garden/docs/): opencode would list it as another skill.
. "$FIXTURES/good-seeds.sh"
printf 'x\n' > garden/docs/SKILL.md
