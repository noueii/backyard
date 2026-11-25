# expect: disable-model-invocation is never allowed
. "$FIXTURES/good-seeds.sh"
sed -i 's/^name: backyard$/name: backyard\ndisable-model-invocation: true/' SKILL.md
