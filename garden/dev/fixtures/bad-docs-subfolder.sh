# expect: docs folders are flat
. "$FIXTURES/good-seeds.sh"
mkdir -p docs/sub && printf 'x\n' > docs/sub/x.md
