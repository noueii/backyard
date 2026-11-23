# expect: garden/ holds only skills, docs, check, dev
. "$FIXTURES/good-seeds.sh"
mkdir -p garden/notes && printf 'x\n' > garden/notes/mine.md
