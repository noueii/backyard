# expect: keys outside the Agent Skills fields: version
. "$FIXTURES/good-seeds.sh"
sed -i '2s/^name: backyard-sync$/name: backyard-sync\nversion: 1/' backyard/skills/backyard-sync/SKILL.md
