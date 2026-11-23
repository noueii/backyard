# expect: garden-memory is mandatory and implicit
. "$FIXTURES/good-seeds.sh"
sed -i 's/optional: \[tdd, /optional: [tdd, garden-memory, /' seeds/reviewer/SEED.md
