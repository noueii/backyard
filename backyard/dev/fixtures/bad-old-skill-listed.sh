# expect: escalate is renamed garden-escalate: don't list it
. "$FIXTURES/good-seeds.sh"
sed -i 's/required: \[garden-escalate, /required: [escalate, /' seeds/task-manager/SEED.md
