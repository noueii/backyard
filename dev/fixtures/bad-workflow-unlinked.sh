# expect: workflow.md exists but SEED.md does not link it
. "$FIXTURES/good-seeds.sh"
sed -i 's/Follow \[workflow.md\](workflow.md)./Plan, build, review./' seeds/task-manager/SEED.md
