# expect: a pending memory has seen: [<task>]
. "$FIXTURES/good-seeds.sh"
sed -i '/^seen: /d' memory/pending/2026-11-23-no-seed-for-git-chores.md
