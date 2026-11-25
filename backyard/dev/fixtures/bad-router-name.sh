# expect: name must be backyard
. "$FIXTURES/good-seeds.sh"
sed -i 's/^name: backyard$/name: seeds/' SKILL.md
