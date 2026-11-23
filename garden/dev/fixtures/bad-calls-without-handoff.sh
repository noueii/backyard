# expect: calls needs handoff
. "$FIXTURES/good-seeds.sh"
sed -i 's/required: \[escalate, handoff, plan-format\]/required: [escalate, plan-format]/' seeds/task-manager/SEED.md
