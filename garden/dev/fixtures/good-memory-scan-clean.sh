# expect: ok
# A committed file edited by hand, cleanly: plain facts, code and words like "token" or "never" mid-sentence pass.
. "$FIXTURES/good-seeds.sh"
printf 'The CI reads its token from the GH_TOKEN secret; it is never printed. Run `make db` first.\n' \
  >> memory/committed/2026-11-23-owner-uses-two-wsl-distros.md
