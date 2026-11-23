# expect: 2026-11-23-owner-uses-two-wsl-distros.md:7: it looks like a secret or token
# A committed file edited by hand, around write.py: the validator scans every line of every memory file.
. "$FIXTURES/good-seeds.sh"
printf 'The CI token is ghp_abcdefghijklmnopqrstuvwxyz0123.\n' >> memory/committed/2026-11-23-owner-uses-two-wsl-distros.md
