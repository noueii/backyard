# expect: backyard and backyard-* are backyard's own names
# The owner's skill may not take backyard's prefix: in tools that list nested skills it would pose as backyard's.
. "$FIXTURES/good-seeds.sh"
mkdir -p skills/backyard-escalate && printf -- '---\nname: backyard-escalate\ndescription: "x. Use when y."\n---\nx\n' > skills/backyard-escalate/SKILL.md
