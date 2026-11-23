# expect: the promotion gate
# A memory seen by one task, put in committed/ by hand (and indexed): it skipped promotion.
. "$FIXTURES/good-seeds.sh"
git mv -f memory/pending/2026-11-23-no-seed-for-git-chores.md memory/committed/ 2>/dev/null \
  || mv memory/pending/2026-11-23-no-seed-for-git-chores.md memory/committed/
idx memory 2026-11-23-no-seed-for-git-chores.md 'a git chore comes up'
