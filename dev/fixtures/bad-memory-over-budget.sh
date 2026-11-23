# expect: (budget 60)
. "$FIXTURES/good-seeds.sh"
for i in $(seq 1 60); do printf -- '- 2026-11-23 Fact %s.\n' "$i" >> MEMORY.md; done
