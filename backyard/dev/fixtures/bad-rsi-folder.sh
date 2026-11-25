# expect: backyard's rsi skill is merged into backyard-memory
# A half-done migration: backyard/skills/rsi/ is still there.
. "$FIXTURES/good-seeds.sh"
mkdir -p backyard/skills/rsi && printf -- '---\nname: rsi\ndescription: "Old. Use when never."\n---\nx\n' > backyard/skills/rsi/SKILL.md
