# expect: memory folders hold only committed/ and pending/
. "$FIXTURES/good-seeds.sh"
mkdir -p memory/archive && printf 'x\n' > memory/archive/old.md
