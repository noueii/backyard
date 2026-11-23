# expect: not part of the memory layout
# 1.x topic files are gone: detail goes in the memory's own body.
. "$FIXTURES/good-seeds.sh"
printf '# Api\n' > memory/api.md
