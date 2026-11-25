# expect: escalate is renamed backyard-escalate: don't list it
. "$FIXTURES/good-seeds.sh"
sed -i 's/required: \[backyard-escalate, /required: [escalate, /' seeds/task-manager/SEED.md
