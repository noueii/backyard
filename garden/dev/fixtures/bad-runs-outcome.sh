# expect: outcome 'ok'
. "$FIXTURES/good-seeds.sh"
printf -- '- 2026-11-25 10:00 | x | ok | - | note\n' >> seeds/reviewer/memory/runs.md
