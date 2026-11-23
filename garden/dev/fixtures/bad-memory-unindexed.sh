# expect: not listed in INDEX.md
. "$FIXTURES/good-seeds.sh"
mem memory/committed/2026-11-24-owner-prefers-squash.md preference 'owner: "squash merges"' - "The owner squash-merges."
