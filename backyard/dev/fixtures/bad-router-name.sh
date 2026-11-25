# expect: name must be garden
. "$FIXTURES/good-seeds.sh"
sed -i 's/^name: garden$/name: seeds/' SKILL.md
