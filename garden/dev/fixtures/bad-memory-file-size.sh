# expect: (budget 1200)
. "$FIXTURES/good-seeds.sh"
mem memory/pending/2026-11-23-a-very-long-memory.md lesson x x "$(printf 'word %.0s' $(seq 1 300))"
