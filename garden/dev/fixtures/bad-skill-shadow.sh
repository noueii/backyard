# expect: shadows the shared skill
# A seed's bundled skill with the name of one of the owner's shared skills.
. "$FIXTURES/good-seeds.sh"
for d in skills/lint-rules seeds/reviewer/skills/lint-rules; do
  mkdir -p $d && printf -- '---\nname: lint-rules\ndescription: "x. Use when y."\n---\nx\n' > $d/SKILL.md
done
