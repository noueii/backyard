# expect: disable-model-invocation is never allowed
. "$FIXTURES/good-seeds.sh"
sed -i 's/^name: garden$/name: garden\ndisable-model-invocation: true/' SKILL.md
