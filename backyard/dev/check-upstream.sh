#!/usr/bin/env bash
# Maintainer-only, for noueii/backyard itself: the placeholders of user-owned paths are frozen, so an upstream
# release never touches a user's docs, seeds, memory or root files. Checks that they are unchanged (by hash), that
# upstream ships no seeds, docs, memory or own skills, and that every other file it ships is backyard-owned
# (backyard/docs/upstream-paths.txt: SKILL.md, backyard/ and the justified root exceptions). A user's backyard never runs this.
# Usage: backyard/dev/check-upstream.sh [root]
set -uo pipefail
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_NAMESPACE GIT_PREFIX
R="${1:-$(cd "$(dirname "$0")/../.." && pwd -P)}"
fails=0; fail() { echo "  FAIL $*"; fails=$((fails + 1)); }
FROZEN='382384a0aafafc7895329eccc5beab12a786bbb136b34c7da99f3c3aea8294ed docs/INDEX.md
a3a660efa9eebf365b79ced781475e76685407d7e2d744c262562543a30e5c1f seeds/INDEX.md
ca891e96669a272521e4ddd828cb3ea116ac03a76eebad0883e5d279d462464b memory/INDEX.md
aae15ca1d116c26b2d62ba8ab559571d8daa92b219eeed2621b06b36884f5b35 README.md
e82b405edb70c078d973459bf57f4fe86a0b1d4809db0942913e25d8511bbf4c AGENTS.md
336cc4fbf19beaada7ccf9986414fa91851a8d7a07dfb3ccbe800a69eed0ab49 CLAUDE.md'
while read -r sum path; do
  [ -f "$R/$path" ] || { fail "$path is missing"; continue; }
  [ "$(sha256sum < "$R/$path" | cut -d' ' -f1)" = "$sum" ] || fail "$path changed: user-owned placeholders are frozen"
done <<< "$FROZEN"
for d in docs seeds memory; do
  extra="$(cd "$R/$d" && ls -A | grep -vxE 'INDEX.md|\.gitkeep')"
  [ -z "$extra" ] || fail "$d/ ships more than its placeholder: $(echo $extra)"
done
[ ! -e "$R/skills" ] || fail "skills/ is the owner's own shared skills: upstream ships none (backyard's are in backyard/skills/)"
# Every shipped file is a frozen placeholder or backyard-owned: nothing of backyard's is left beside the owner's content.
owned="$(grep -v '^#' "$R/backyard/docs/upstream-paths.txt" | grep -v '^$')"
placeholders="$(printf '%s\n' "$FROZEN" | cut -d' ' -f2)"
if git -C "$R" rev-parse --show-toplevel >/dev/null 2>&1; then
  shipped="$(git -C "$R" ls-files -co --exclude-standard)"
else
  shipped="$(cd "$R" && find . -type f -not -path './.git/*' | sed 's|^\./||')"
fi
while IFS= read -r f; do
  [ -n "$f" ] || continue
  printf '%s\n' "$placeholders" | grep -qxF -- "$f" && continue
  ok=0
  while IFS= read -r o; do
    case "$o" in */) case "$f" in "$o"*) ok=1 ;; esac ;; *) [ "$f" = "$o" ] && ok=1 ;; esac
  done <<< "$owned"
  [ "$ok" = 1 ] || fail "$f is neither backyard-owned (upstream-paths.txt) nor a frozen placeholder: move it into backyard/"
done <<< "$shipped"
if [ "$fails" = 0 ]; then echo "check-upstream: ok"; else echo "check-upstream: $fails failed"; exit 1; fi
