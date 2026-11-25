# expect: a backyard-owned file outside backyard/
# A half-done move: the 1.x spec still at the root.
. "$FIXTURES/good-seeds.sh"
mkdir -p spec && cp backyard/docs/SPEC.md spec/SPEC.md
