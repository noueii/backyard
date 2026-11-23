# expect: skill nope resolves to neither
. "$FIXTURES/good-seeds.sh"
sed -i 's/optional: \[tdd, /optional: [tdd, nope, /' seeds/reviewer/SEED.md
