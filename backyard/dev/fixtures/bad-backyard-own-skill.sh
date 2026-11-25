# expect: not one of backyard's skills: your own shared skills go in skills/plan-format/
. "$FIXTURES/good-seeds.sh"
mkdir -p backyard/skills/plan-format && printf -- '---\nname: plan-format\ndescription: "x. Use when y."\n---\nx\n' > backyard/skills/plan-format/SKILL.md
