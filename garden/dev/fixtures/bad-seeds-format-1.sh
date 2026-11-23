# expect: seeds-format 1.0: this validator knows major 2
. "$FIXTURES/good-seeds.sh"
sed -i 's/seeds-format: "2.0"/seeds-format: "1.0"/' SKILL.md
