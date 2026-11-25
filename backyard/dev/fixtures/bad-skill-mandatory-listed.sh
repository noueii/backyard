# expect: backyard-memory is mandatory and implicit
. "$FIXTURES/good-seeds.sh"
sed -i 's/optional: \[tdd, /optional: [tdd, backyard-memory, /' seeds/reviewer/SEED.md
