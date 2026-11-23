#!/usr/bin/env bash
# Maintainer-only: tests the scripts that ship inside skills, in temp git repos. No network, no AI.
#   skills/sync/sync.sh: an upstream (noueii/garden), a user's origin and two clones of it.
# Usage: dev/test-scripts.sh
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
export HOME="$T/home" XDG_STATE_HOME="$T/state" GARDEN_NO_GH=1 GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=you GIT_AUTHOR_EMAIL=you@example.com GIT_COMMITTER_NAME=you GIT_COMMITTER_EMAIL=you@example.com
mkdir -p "$HOME"; git config --global init.defaultBranch main; git config --global advice.detachedHead false
fails=0; pass() { echo "  ok   $*"; }; fail() { echo "  FAIL $*"; fails=$((fails + 1)); }
expect() { # <description> <expected exit> <command...>: runs it, keeps its output in $OUT
  local d="$1" want="$2"; shift 2
  OUT="$("$@" 2>&1)"; local got=$?
  [ "$got" = "$want" ] && pass "$d" || { fail "$d (exit $got, wanted $want):"; echo "$OUT" | sed 's/^/         /'; }
}
has() { printf '%s' "$OUT" | grep -qF -- "$1" && pass "  … says: $1" || { fail "  … should say: $1"; echo "$OUT" | sed 's/^/         /'; }; }
memline() { # <clone> <text>: add a memory line at the top of MEMORY.md's list and commit it
  python3 - "$1/MEMORY.md" "$2" <<'PY'
import sys
p, t = sys.argv[1], sys.argv[2]
lines = open(p).read().splitlines()
i = next((n for n, l in enumerate(lines) if l.startswith("- ")), len(lines))
lines.insert(i, f"- 2026-11-23 {t}")
open(p, "w").write("\n".join(lines) + "\n")
PY
  git -C "$1" commit -qam "memory: $2"
}

echo "sync.sh"
# upstream: this repo as it is on disk, tagged v1.0.0
mkdir -p "$T/up"
(cd "$ROOT" && git ls-files -co --exclude-standard | while IFS= read -r f; do [ -e "$f" ] && printf '%s\0' "$f"; done \
  | tar --null -T - -cf -) | (cd "$T/up" && tar -xf -)
git -C "$T/up" init -q && git -C "$T/up" add -A && git -C "$T/up" commit -qm "garden 1.0.0" && git -C "$T/up" tag v1.0.0
git clone -q --bare "$T/up" "$T/up.git"
# the user's garden: a copy of upstream with its own (bare) origin
git clone -q "$T/up.git" "$T/g" && git -C "$T/g" remote rename origin upstream
git init -q --bare "$T/origin.git" && git -C "$T/g" remote add origin "$T/origin.git" && git -C "$T/g" push -q -u origin main
git -C "$T/origin.git" symbolic-ref HEAD refs/heads/main
git clone -q "$T/origin.git" "$T/g2"
S="$T/g/skills/sync/sync.sh"; S2="$T/g2/skills/sync/sync.sh"

expect "status on a fresh garden" 0 bash "$S" status
has "pull: up to date"
expect "a folder without git is refused" 1 bash "$S" status "$T"
has "not a git clone"

memline "$T/g" "fact one"
expect "memory: pushes a memory commit" 0 bash "$S" memory
has "pushed 1 memory commit(s) to main"
[ "$(git -C "$T/origin.git" log -1 --format=%s main)" = "memory: fact one" ] && pass "  … origin has it" || fail "  … origin lacks it"
expect "pull: fast-forwards the other clone" 0 bash "$S2" pull
has "fast-forwarded"

memline "$T/g2" "fact from g2"
memline "$T/g" "fact from g"; bash "$S" memory >/dev/null
expect "pull: replays local memory commits onto origin" 0 bash "$S2" pull
has "replayed 1 local memory commit(s)"
grep -q "fact from g2" "$T/g2/MEMORY.md" && grep -q "fact from g$" "$T/g2/MEMORY.md" \
  && pass "  … MEMORY.md keeps both lines (merge=union)" || fail "  … MEMORY.md lost a line"
[ "$(git -C "$T/g2" rev-list --merges --count HEAD)" = 0 ] && pass "  … no merge commit" || fail "  … made a merge commit"
expect "memory: pushes the replayed commit" 0 bash "$S2" memory

echo "x" > "$T/g2/docs/notes.md"; git -C "$T/g2" add -A; git -C "$T/g2" commit -qm "docs by hand"
expect "memory: refuses a non-memory commit" 1 bash "$S2" memory
has "touch more than memory"
memline "$T/g" "fact three"; bash "$S" pull >/dev/null; bash "$S" memory >/dev/null
expect "pull: refuses to replay a non-memory commit" 1 bash "$S2" pull
has "docs/notes.md"
git clone -q "$T/origin.git" "$T/g3"; memline "$T/g3" "fact from g3"; git -C "$T/g3" push -q origin main
echo dirty >> "$T/g/MEMORY.md"
expect "pull: refuses with uncommitted changes" 1 bash "$S" pull
has "commit memory first"
git -C "$T/g" checkout -q -- MEMORY.md

git -C "$T/g" branch -q garden/20261123-1200-fix-seeds
git -C "$T/g" worktree add -q "$T/wt" garden/20261123-1200-fix-seeds
echo "# Style" > "$T/wt/docs/style.md"; git -C "$T/wt" add -A; git -C "$T/wt" commit -qm "seeds(x): add a style doc"
expect "staged: skips a branch whose stage is still open" 0 bash "$S" staged
has "no finished garden/* branches"
git -C "$T/g" worktree remove "$T/wt"
expect "staged: pushes a finished branch (no gh)" 0 bash "$S" staged
has "pushed garden/20261123-1200-fix-seeds"
has "open the PR for garden/20261123-1200-fix-seeds by hand"
git -C "$T/origin.git" rev-parse -q --verify refs/heads/garden/20261123-1200-fix-seeds >/dev/null \
  && pass "  … origin has the branch" || fail "  … origin lacks the branch"
expect "staged: a second run changes nothing" 0 bash "$S" staged
has "open the PR for"

expect "upstream: up to date" 0 bash "$S" upstream
has "up to date with v1.0.0"
echo "release note" >> "$T/up/README.md"; git -C "$T/up" commit -qam "readme: release note"; git -C "$T/up" tag v1.0.1
git -C "$T/up" push -q "$T/up.git" main --tags
before="$(git -C "$T/g" rev-parse HEAD)"
expect "upstream: stages a release on a root branch" 0 bash "$S" upstream
has "staged v1.0.1 on garden/"
b="$(git -C "$T/g" for-each-ref --format='%(refname:short)' 'refs/heads/garden/*upstream*')"
[ "$(git -C "$T/g" rev-parse HEAD)" = "$before" ] && pass "  … the default branch is untouched" || fail "  … the default branch moved"
git -C "$T/g" merge-base --is-ancestor v1.0.1 "$b" && pass "  … $b contains v1.0.1" || fail "  … the branch lacks v1.0.1"
[ "$(git -C "$T/g" log -1 --format=%s "$b")" = "root: garden v1.0.1" ] && pass "  … titled root: garden v1.0.1" || fail "  … wrong title"
expect "upstream: a second run doesn't stage it again" 0 bash "$S" upstream
has "already has a branch"

sed -i 's/^# garden$/# garden (mine)/' "$T/g/SKILL.md"; git -C "$T/g" commit -qam "root: my title"
sed -i 's/^# garden$/# garden (upstream)/' "$T/up/SKILL.md"; git -C "$T/up" commit -qam "router: new title"; git -C "$T/up" tag v1.0.2
git -C "$T/up" push -q "$T/up.git" main --tags
expect "upstream: a conflict stops with exit 3" 3 bash "$S" upstream
has "SKILL.md"
has "resolve them"

echo
if [ "$fails" = 0 ]; then echo "test-scripts: all passed"; else echo "test-scripts: $fails failed"; exit 1; fi
