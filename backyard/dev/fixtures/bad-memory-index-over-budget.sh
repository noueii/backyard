# expect: 51 entries (budget 50)
. "$FIXTURES/good-seeds.sh"
for i in $(seq 1 50); do idx memory 2026-11-23-owner-uses-two-wsl-distros.md "copy $i"; done
