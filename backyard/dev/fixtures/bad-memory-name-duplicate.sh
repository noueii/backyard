# expect: one memory per description
# The same description pending and committed: one memory, two files.
. "$FIXTURES/good-seeds.sh"
mem memory/pending/2026-11-25-owner-uses-two-wsl-distros.md fact x x "Again."
