# expect: needs metadata.commit
. "$FIXTURES/good-seeds.sh"
sed -i 's/, commit: "[0-9a-f]*"//' seeds/reviewer/skills/tdd/ENTRY.md
