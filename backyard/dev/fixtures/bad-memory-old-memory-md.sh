# expect: MEMORY.md is gone since seeds-format 2.0
# A half-done migration: the 1.x MEMORY.md is still there.
. "$FIXTURES/good-seeds.sh"
printf '# Memory\n' > seeds/reviewer/MEMORY.md
