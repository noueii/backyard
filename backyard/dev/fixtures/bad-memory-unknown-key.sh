# expect: unknown frontmatter keys: priority
. "$FIXTURES/good-seeds.sh"
sed -i 's/^type: lesson$/type: lesson\npriority: high/' memory/pending/2026-11-23-no-seed-for-git-chores.md
