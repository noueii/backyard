# expect: a garden skill's description starts with "Part of the garden skill"
# Without it, a tool that lists nested skills (opencode) offers garden-sync as if it stood on its own.
. "$FIXTURES/good-seeds.sh"
sed -i '3s/Part of the garden skill, used through its router and seeds, never on its own. //' garden/skills/garden-sync/SKILL.md
