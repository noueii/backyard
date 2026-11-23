# expect: ok
# The bare names garden gave up (escalate, sync, ...) are free for the owner's own skills.
. "$FIXTURES/good-seeds.sh"
mkdir -p skills/sync && printf -- '---\nname: sync\ndescription: "The owner'"'"'s own sync notes. Use when syncing dotfiles."\n---\nx\n' > skills/sync/SKILL.md
sed -i 's/optional: \[tdd, /optional: [tdd, sync, /' seeds/reviewer/SEED.md
