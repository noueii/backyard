# expect: a SKILL.md is allowed only at the root and as a skill's own file
. "$FIXTURES/good-seeds.sh"
printf -- '---\nname: reviewer\ndescription: "x. Use when y."\n---\nx\n' > seeds/reviewer/SKILL.md
