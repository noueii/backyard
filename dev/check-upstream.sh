#!/usr/bin/env bash
# Maintainer-only, for noueii/garden itself: the placeholders of user-owned paths are frozen, so an upstream
# release never touches a user's docs, seeds or memory. Checks that they are unchanged (by hash) and that
# upstream ships no seeds, no docs and no memory. A user's garden never runs this.
# Usage: dev/check-upstream.sh [root]
set -uo pipefail
R="${1:-$(cd "$(dirname "$0")/.." && pwd -P)}"
fails=0; fail() { echo "  FAIL $*"; fails=$((fails + 1)); }
while read -r sum path; do
  [ -f "$R/$path" ] || { fail "$path is missing"; continue; }
  [ "$(sha256sum < "$R/$path" | cut -d' ' -f1)" = "$sum" ] || fail "$path changed: user-owned placeholders are frozen"
done <<'SUMS'
382384a0aafafc7895329eccc5beab12a786bbb136b34c7da99f3c3aea8294ed docs/INDEX.md
a3a660efa9eebf365b79ced781475e76685407d7e2d744c262562543a30e5c1f seeds/INDEX.md
b01f47c0e4aa34580b8ddf3140acc94de3a44517c603aa1c6ee595855a042aa8 MEMORY.md
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 memory/.gitkeep
SUMS
for d in docs seeds memory; do
  extra="$(cd "$R/$d" && ls -A | grep -vxE 'INDEX.md|\.gitkeep')"
  [ -z "$extra" ] || fail "$d/ ships more than its placeholder: $(echo $extra)"
done
if [ "$fails" = 0 ]; then echo "check-upstream: ok"; else echo "check-upstream: $fails failed"; exit 1; fi
