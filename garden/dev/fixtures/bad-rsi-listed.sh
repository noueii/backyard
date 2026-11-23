# expect: rsi is merged into memory (seeds-format 2.0): don't list it
. "$FIXTURES/good-seeds.sh"
sed -i 's/optional: \[tdd, /optional: [tdd, rsi, /' seeds/reviewer/SEED.md
