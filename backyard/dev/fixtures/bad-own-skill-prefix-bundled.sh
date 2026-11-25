# expect: backyard and backyard-* are backyard's own names
. "$FIXTURES/good-seeds.sh"
mkdir -p seeds/reviewer/skills/backyard && printf -- '---\nname: backyard\ndescription: "x. Use when y."\n---\nx\n' > seeds/reviewer/skills/backyard/SKILL.md
