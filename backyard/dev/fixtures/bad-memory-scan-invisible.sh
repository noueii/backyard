# expect: 2026-11-23-owner-uses-two-wsl-distros.md:7: invisible or control character U+200B
. "$FIXTURES/good-seeds.sh"
printf 'Deploys go through \342\200\213staging.\n' >> memory/committed/2026-11-23-owner-uses-two-wsl-distros.md
