# expect: garden and garden-* are garden's own names
. "$FIXTURES/good-seeds.sh"
mkdir -p seeds/reviewer/skills/garden && printf -- '---\nname: garden\ndescription: "x. Use when y."\n---\nx\n' > seeds/reviewer/skills/garden/SKILL.md
