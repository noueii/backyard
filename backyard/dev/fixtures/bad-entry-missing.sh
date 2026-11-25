# expect: SKILL.md: required file is missing
. "$FIXTURES/good-seeds.sh"
mkdir -p skills/empty && printf 'x\n' > skills/empty/README.md
