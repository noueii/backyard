# expect: not one of garden's skills: your own shared skills go in skills/plan-format/
. "$FIXTURES/good-seeds.sh"
mkdir -p garden/skills/plan-format && printf -- '---\nname: plan-format\ndescription: "x. Use when y."\n---\nx\n' > garden/skills/plan-format/SKILL.md
