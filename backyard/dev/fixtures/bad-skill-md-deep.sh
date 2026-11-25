# expect: a SKILL.md is allowed only at the root and as a skill's own file
# A SKILL.md below a skill's folder (a vendored skill's sub-skill, say) is not a garden skill.
. "$FIXTURES/good-seeds.sh"
mkdir -p seeds/reviewer/skills/tdd/inner && printf -- '---\nname: inner\ndescription: "x. Use when y."\n---\nx\n' > seeds/reviewer/skills/tdd/inner/SKILL.md
