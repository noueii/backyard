# expect: calls coder, which is not a seed
. "$FIXTURES/good-seeds.sh"
sed -i 's/^calls: \[reviewer\]$/calls: [reviewer, coder]/' seeds/task-manager/SEED.md
