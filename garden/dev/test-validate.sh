#!/usr/bin/env bash
# Maintainer-only: tests garden/check/validate.py. The repo itself must pass; then each garden/dev/fixtures/<name>.sh is applied
# to a fresh temp copy of the repo and validated. Its first line, "# expect: <text>", is either "ok" (the copy
# must pass) or a text the validator's output must contain (the copy must fail). Fixtures are shell overlays, so
# the repo never stores a second SKILL.md.
# Usage: garden/dev/test-validate.sh [fixture-name...]
set -uo pipefail
# Ignore a repo chosen by the caller's environment (git sets these in hooks and `rebase -x`): every git call
# here names its repo explicitly.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_NAMESPACE GIT_PREFIX
ROOT="$(cd "$(dirname "$0")/../.." && pwd -P)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
export FIXTURES="$ROOT/garden/dev/fixtures"
fails=0; pass() { echo "  ok   $*"; }; fail() { echo "  FAIL $*"; fails=$((fails + 1)); }

copy() { # <dest>: the repo's tracked and untracked (not ignored) files, as they are on disk
  mkdir -p "$1"
  (cd "$ROOT" && git ls-files -co --exclude-standard | while IFS= read -r f; do [ -e "$f" ] && printf '%s\0' "$f"; done \
    | tar --null -T - -cf -) | (cd "$1" && tar -xf -)
}

echo "the repo"
if out="$(python3 "$ROOT/garden/check/validate.py" "$ROOT" 2>&1)"; then pass "validate.py passes on the repo"
else fail "validate.py fails on the repo:"; echo "$out" | sed 's/^/         /'; fi

echo "fixtures"
names="${*:-$(cd "$FIXTURES" && ls *.sh | sed 's/\.sh$//')}"
for name in $names; do
  f="$FIXTURES/$name.sh"
  expect="$(sed -n '1s/^# expect: //p' "$f")"
  [ -n "$expect" ] || { fail "$name: no '# expect:' line"; continue; }
  d="$T/$name"; copy "$d"
  if ! (cd "$d" && bash -e "$f") > "$T/$name.apply" 2>&1; then fail "$name: the overlay failed: $(tail -1 "$T/$name.apply")"; continue; fi
  out="$(python3 "$ROOT/garden/check/validate.py" "$d" 2>&1)"; code=$?
  if [ "$expect" = ok ]; then
    [ "$code" = 0 ] && pass "$name passes" || { fail "$name should pass:"; echo "$out" | sed 's/^/         /'; }
  elif [ "$code" = 1 ] && printf '%s' "$out" | grep -qF -- "$expect"; then
    pass "$name fails with: $expect"
  else
    fail "$name: expected a failure with \"$expect\", got exit $code:"; echo "$out" | sed 's/^/         /'
  fi
done

echo
if [ "$fails" = 0 ]; then echo "test-validate: all passed"; else echo "test-validate: $fails failed"; exit 1; fi
