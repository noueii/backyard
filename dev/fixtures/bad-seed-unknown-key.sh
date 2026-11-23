# expect: unknown keys: may_change
. "$FIXTURES/good-seeds.sh"
sed -i 's/^access: read-only$/access: read-only\nmay_change: nothing/' seeds/reviewer/SEED.md
