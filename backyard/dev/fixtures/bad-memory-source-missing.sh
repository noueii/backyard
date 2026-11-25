# expect: source is missing
. "$FIXTURES/good-seeds.sh"
sed -i '/^source: /d' memory/pending/2026-11-23-no-seed-for-git-chores.md
