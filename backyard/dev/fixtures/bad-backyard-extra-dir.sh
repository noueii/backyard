# expect: backyard/ holds only skills, docs, check, dev
. "$FIXTURES/good-seeds.sh"
mkdir -p backyard/notes && printf 'x\n' > backyard/notes/mine.md
