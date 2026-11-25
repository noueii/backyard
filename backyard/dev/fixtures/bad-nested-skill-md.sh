# expect: a SKILL.md is allowed only at the root and as a skill's own file
# Another casing, even in a skill folder: case-insensitive filesystems make it the same file.
. "$FIXTURES/good-seeds.sh"
mkdir -p seeds/reviewer/skills/x && printf 'x\n' > seeds/reviewer/skills/x/skill.md
