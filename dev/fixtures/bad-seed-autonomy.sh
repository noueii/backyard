# expect: without escalate, autonomy
. "$FIXTURES/good-seeds.sh"
sed -i '/^autonomy:/d' seeds/reviewer/SEED.md
