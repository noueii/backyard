# expect: rsi is merged into garden-memory: don't list it
. "$FIXTURES/good-seeds.sh"
sed -i 's/optional: \[tdd, /optional: [tdd, rsi, /' seeds/reviewer/SEED.md
