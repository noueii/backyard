# expect: seed task-manager is not listed
. "$FIXTURES/good-seeds.sh"
sed -i '/^- task-manager:/d' seeds/INDEX.md
