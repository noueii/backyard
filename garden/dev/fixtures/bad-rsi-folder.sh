# expect: garden's rsi skill is merged into memory
# A half-done migration: garden/skills/rsi/ is still there.
. "$FIXTURES/good-seeds.sh"
mkdir -p garden/skills/rsi && printf -- '---\nname: rsi\ndescription: "Old. Use when never."\n---\nx\n' > garden/skills/rsi/ENTRY.md
