# expect: skill nope resolves to none of
. "$FIXTURES/good-seeds.sh"
sed -i 's/optional: \[tdd, /optional: [tdd, nope, /' seeds/reviewer/SEED.md
