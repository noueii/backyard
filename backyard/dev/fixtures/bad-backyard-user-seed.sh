# expect: your own content (seeds, docs indexes, memory) never goes inside garden/
. "$FIXTURES/good-seeds.sh"
mkdir -p garden/dev/seeds/x && printf 'x\n' > garden/dev/seeds/x/notes.md
