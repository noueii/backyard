# expect: is garden's skill: it lives in garden/skills/escalate
. "$FIXTURES/good-seeds.sh"
mkdir -p skills/escalate && printf -- '---\nname: escalate\ndescription: "x. Use when y."\n---\nx\n' > skills/escalate/ENTRY.md
