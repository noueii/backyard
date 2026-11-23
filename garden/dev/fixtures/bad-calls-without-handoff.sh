# expect: calls needs garden-handoff
. "$FIXTURES/good-seeds.sh"
sed -i 's/required: \[garden-escalate, garden-handoff, plan-format\]/required: [garden-escalate, plan-format]/' seeds/task-manager/SEED.md
