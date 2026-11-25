# expect: calls needs backyard-handoff
. "$FIXTURES/good-seeds.sh"
sed -i 's/required: \[backyard-escalate, backyard-handoff, plan-format\]/required: [backyard-escalate, plan-format]/' seeds/task-manager/SEED.md
