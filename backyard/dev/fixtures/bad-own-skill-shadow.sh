# expect: garden and garden-* are garden's own names
# The owner's skill may not take garden's prefix: in tools that list nested skills it would pose as garden's.
. "$FIXTURES/good-seeds.sh"
mkdir -p skills/garden-escalate && printf -- '---\nname: garden-escalate\ndescription: "x. Use when y."\n---\nx\n' > skills/garden-escalate/SKILL.md
