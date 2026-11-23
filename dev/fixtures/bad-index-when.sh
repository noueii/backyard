# expect: when differs from
. "$FIXTURES/good-seeds.sh"
sed -i 's/^- reviewer: Reviewing a pull request/- reviewer: Reviewing a PR/' seeds/INDEX.md
