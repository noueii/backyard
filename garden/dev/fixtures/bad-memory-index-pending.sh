# expect: pending memories are never indexed
. "$FIXTURES/good-seeds.sh"
printf -- '- [2026-11-23-no-seed-for-git-chores.md](pending/2026-11-23-no-seed-for-git-chores.md): read when a chore comes up.\n' >> memory/INDEX.md
