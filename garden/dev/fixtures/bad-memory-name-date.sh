# expect: 2026-13-40 is not a date
. "$FIXTURES/good-seeds.sh"
mem memory/pending/2026-13-40-bad-date-here.md lesson x x "A note."
