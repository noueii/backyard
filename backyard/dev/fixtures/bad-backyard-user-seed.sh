# expect: your own content (seeds, docs indexes, memory) never goes inside backyard/
. "$FIXTURES/good-seeds.sh"
mkdir -p backyard/dev/seeds/x && printf 'x\n' > backyard/dev/seeds/x/notes.md
