# expect: autonomy is only set when backyard-escalate is not in skills
. "$FIXTURES/good-seeds.sh"
sed -i 's/^calls: \[reviewer\]$/calls: [reviewer]\nautonomy: stop-and-record/' seeds/task-manager/SEED.md
