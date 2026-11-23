# expect: date is missing or differs from the date in the file name
. "$FIXTURES/good-seeds.sh"
sed -i 's/^date: .*/date: 2026-01-01/' memory/pending/2026-11-23-no-seed-for-git-chores.md
