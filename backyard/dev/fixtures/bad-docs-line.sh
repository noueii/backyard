# expect: not an index line
. "$FIXTURES/good-seeds.sh"
printf -- '- testing: tests\n' >> seeds/reviewer/docs/INDEX.md
