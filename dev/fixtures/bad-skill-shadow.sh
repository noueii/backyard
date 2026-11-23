# expect: shadows the shared skill
. "$FIXTURES/good-seeds.sh"
mkdir -p seeds/reviewer/skills/escalate && printf -- '---\nname: escalate\ndescription: "x. Use when y."\n---\nx\n' > seeds/reviewer/skills/escalate/ENTRY.md
