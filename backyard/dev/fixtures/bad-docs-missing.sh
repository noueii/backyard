# expect: lists gone.md, which does not exist
. "$FIXTURES/good-seeds.sh"
printf -- '- [gone.md](gone.md): read when never.\n' >> docs/INDEX.md
