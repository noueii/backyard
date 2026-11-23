# expect: keys outside the Agent Skills fields: version
. "$FIXTURES/good-seeds.sh"
sed -i '2s/^name: garden-sync$/name: garden-sync\nversion: 1/' garden/skills/garden-sync/SKILL.md
