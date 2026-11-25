# expect: ok
# The owner's own shared skill lives in skills/ at the root, beside backyard/skills/, and a seed uses it by bare name.
. "$FIXTURES/good-seeds.sh"
mkdir -p skills/lint-rules
printf -- '---\nname: lint-rules\ndescription: "The owner'"'"'s lint rules. Use when reviewing style."\n---\nNo unused imports.\n' > skills/lint-rules/SKILL.md
sed -i 's/optional: \[tdd, /optional: [tdd, lint-rules, /' seeds/reviewer/SEED.md
