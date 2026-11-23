# expect: an unrouted line's outcome is one-off
. "$FIXTURES/good-seeds.sh"
printf -- '- 2026-11-25 10:00 | x | done | - | note\n' >> memory/unrouted.md
