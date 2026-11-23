# expect: names memory/gone.md, which does not exist
. "$FIXTURES/good-seeds.sh"
printf -- '- 2026-11-23 See memory/gone.md.\n' >> MEMORY.md
