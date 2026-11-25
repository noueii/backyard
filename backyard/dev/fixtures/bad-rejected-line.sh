# expect: not a rejected line
. "$FIXTURES/good-seeds.sh"
printf -- '# Rejected\n\n- 2026-11-23 no pipes here\n' > memory/rejected.md
