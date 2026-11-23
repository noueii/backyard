# expect: access 'write'
. "$FIXTURES/good-seeds.sh"
sed -i 's/^access: read-only$/access: write/' seeds/reviewer/SEED.md
