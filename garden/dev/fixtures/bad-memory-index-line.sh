# expect: not an index line
. "$FIXTURES/good-seeds.sh"
printf -- '- 2026-11-23 The api needs make db.\n' >> seeds/task-manager/memory/INDEX.md
