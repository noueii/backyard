# expect: a garden-owned file outside garden/
# A half-done move: the 1.x spec still at the root.
. "$FIXTURES/good-seeds.sh"
mkdir -p spec && cp garden/docs/SPEC.md spec/SPEC.md
