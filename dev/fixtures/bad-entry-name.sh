# expect: must equal the folder name
. "$FIXTURES/good-seeds.sh"
sed -i 's/^name: plan-format$/name: plans/' seeds/task-manager/skills/plan-format/ENTRY.md
