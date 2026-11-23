#!/usr/bin/env bash
# Usage: sync.sh <step> [garden root]     steps, in the order `all` runs them:
#   pull        fetch origin; fast-forward, or rebase local commits that touch memory paths only; never a merge commit
#   memory      push local commits to origin's default branch, only if every one touches memory paths only
#   upstream    fetch upstream's newest v<major>.* tag and stage it on a root-tier branch that merges it (with no
#               origin, a garden with no commits of its own fast-forwards instead)
#   staged      push each finished local garden/* branch and open its PR (gh pr create --fill); never merges
#   decisions   record garden/* PRs closed without merging in memory/rejected.md (through memory/write.py)
#   all         the five above, stopping at the first failure
#   status      what each step would do; changes nothing
# Exit: 0 done, 1 refused or failed (the reason is printed), 2 usage, 3 the upstream merge needs you (conflicts).
# Never force-pushes, never merges a PR, never runs on its own. GARDEN_NO_GH=1 acts as if gh were missing.
set -uo pipefail
# Ignore a repo chosen by the caller's environment (git sets these in hooks and `rebase -x`): every git call
# here names its repo explicitly.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_NAMESPACE GIT_PREFIX

step="${1:-}"; R="${2:-$(cd "$(dirname "$0")/../../.." && pwd -P)}"
case "$step" in pull|memory|staged|upstream|decisions|all|status) ;; *) sed -n '2,13p' "$0"; exit 2 ;; esac
g() { git -C "$R" "$@"; }
say() { echo "sync: $*"; }
g rev-parse --show-toplevel >/dev/null 2>&1 || { say "not a git clone ($R): nothing to sync (a read-only install)"; exit 1; }
R="$(g rev-parse --show-toplevel)"
has_gh() { [ "${GARDEN_NO_GH:-}" != 1 ] && command -v gh >/dev/null && (cd "$R" && gh auth status >/dev/null 2>&1); }
has_remote() { g remote get-url "$1" >/dev/null 2>&1; }

is_memory_path() { case "$1" in MEMORY.md|memory/*|seeds/*/MEMORY.md|seeds/*/memory/*) return 0 ;; *) return 1 ;; esac; }
non_memory() { # <range>: files outside memory paths touched by the commits in range
  local f
  g log --format= --name-only "$1" | sort -u | while IFS= read -r f; do
    [ -n "$f" ] && ! is_memory_path "$f" && echo "$f"
  done
}
default_branch() {
  local b; b="$(g symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null)"; b="${b#origin/}"
  [ -n "$b" ] || b="$(g ls-remote --symref origin HEAD 2>/dev/null | sed -n 's|^ref: refs/heads/\(.*\)\tHEAD$|\1|p')"
  echo "${b:-main}"
}
need_clean_default() {
  local cur; cur="$(g branch --show-current)"
  [ "$cur" = "$DEF" ] || { say "on branch '$cur', not the default branch '$DEF': stopped"; return 1; }
  [ -z "$(g status --porcelain --untracked-files=no)" ] || {
    say "uncommitted changes in the live clone; commit memory first (garden/skills/memory/ENTRY.md): stopped"; g status --short | sed 's/^/  /'; return 1; }
}

DEF=main; has_remote origin && DEF="$(default_branch)"
DRY=0; [ "$step" = status ] && DRY=1

do_pull() {
  has_remote origin || { say "pull: no origin, skipped"; return 0; }
  g fetch -q origin || { say "pull: git fetch origin failed"; return 1; }
  local o="origin/$DEF"
  g rev-parse -q --verify "$o" >/dev/null || { say "pull: origin has no $DEF yet, nothing to pull"; return 0; }
  local behind ahead; behind="$(g rev-list --count "HEAD..$o")"; ahead="$(g rev-list --count "$o..HEAD")"
  [ "$behind" = 0 ] && { say "pull: up to date with $o ($ahead local commit(s) ahead)"; return 0; }
  [ "$DRY" = 1 ] && { say "pull: would bring in $behind commit(s) from $o"; return 0; }
  need_clean_default || return 1
  if [ "$ahead" = 0 ]; then
    g merge -q --ff-only "$o" && say "pull: fast-forwarded to $o ($behind commit(s))"; return
  fi
  local bad; bad="$(non_memory "$o..HEAD")"
  if [ -n "$bad" ]; then
    say "pull: refused: local commits on $DEF touch more than memory, so they can't be replayed safely:"
    printf '  %s\n' $bad; say "move them to a garden/* branch, or resolve by hand"; return 1
  fi
  if g rebase -q "$o" >/dev/null 2>&1; then
    say "pull: brought in $behind commit(s) from $o and replayed $ahead local memory commit(s) on top"
  else
    g rebase --abort >/dev/null 2>&1
    say "pull: the memory commits did not replay cleanly onto $o; nothing changed. Resolve by hand"; return 1
  fi
}

do_memory() {
  has_remote origin || { say "memory: no origin, skipped"; return 0; }
  g fetch -q origin || { say "memory: git fetch origin failed"; return 1; }
  local o="origin/$DEF" range
  g rev-parse -q --verify "$o" >/dev/null && range="$o..HEAD" || range="HEAD"
  local n; n="$(g rev-list --count "$range")"
  [ "$n" = 0 ] && { say "memory: nothing to push"; return 0; }
  if g rev-parse -q --verify "$o" >/dev/null && [ "$(g rev-list --count "HEAD..$o")" != 0 ]; then
    say "memory: $o has commits you don't: run the pull step first"; return 1; fi
  local bad; bad="$(non_memory "$range")"
  [ -z "$bad" ] || { say "memory: refused: commits ahead of $o touch more than memory:"; printf '  %s\n' $bad; return 1; }
  [ "$DRY" = 1 ] && { say "memory: would push $n memory commit(s) to $DEF"; return 0; }
  need_clean_default || return 1
  g push -q origin "HEAD:refs/heads/$DEF" && say "memory: pushed $n memory commit(s) to $DEF"
}

finished_branches() { # local garden/* branches with no worktree checked out
  local busy; busy="$(g worktree list --porcelain | sed -n 's|^branch refs/heads/||p')"
  g for-each-ref --format='%(refname:short)' 'refs/heads/garden/' | while IFS= read -r b; do
    printf '%s\n' "$busy" | grep -qxF "$b" || echo "$b"
  done
}

do_staged() {
  local bs; bs="$(finished_branches)"
  [ -n "$bs" ] || { say "staged: no finished garden/* branches"; return 0; }
  has_remote origin || { say "staged: no origin; the branches stay local:"; printf '  %s\n' $bs; return 0; }
  local b rc=0 gh=0; has_gh && gh=1
  for b in $bs; do
    local remote; remote="$(g ls-remote origin "refs/heads/$b" | cut -f1)"
    if [ "$DRY" = 1 ]; then
      [ "$remote" = "$(g rev-parse "$b")" ] && say "staged: $b is pushed" || say "staged: would push $b and open its PR"; continue
    fi
    if [ "$remote" != "$(g rev-parse "$b")" ]; then
      [ -n "$remote" ] && { say "staged: origin's $b differs from yours; not force-pushing it"; rc=1; continue; }
      g push -q -u origin "$b" || { say "staged: pushing $b failed"; rc=1; continue; }
      say "staged: pushed $b"
    fi
    if [ "$gh" = 1 ]; then
      local url; url="$(cd "$R" && gh pr list --head "$b" --state all --json url --jq '.[0].url' 2>/dev/null)"
      if [ -n "$url" ]; then say "staged: $b already has a PR: $url"
      else url="$(cd "$R" && gh pr create --head "$b" --base "$DEF" --fill 2>&1)" && say "staged: opened $url" \
             || { say "staged: gh pr create failed for $b: $url"; rc=1; }
      fi
    else
      say "staged: no gh (or not logged in): open the PR for $b by hand"
    fi
  done
  return $rc
}

do_upstream() {
  has_remote upstream || { say "upstream: no upstream remote (git remote add upstream https://github.com/noueii/garden), skipped"; return 0; }
  g fetch -q --tags upstream || { say "upstream: git fetch upstream failed"; return 1; }
  local major tag; major="$(sed -n 's/^  version: "\([0-9]*\)\..*/\1/p' "$R/SKILL.md")"; major="${major:-1}"
  tag="$(g tag -l "v$major.*" --sort=-v:refname | head -1)"
  [ -n "$tag" ] || { say "upstream: no v$major.* release yet"; return 0; }
  if g merge-base --is-ancestor "$tag" HEAD; then say "upstream: up to date with $tag"; return 0; fi
  local newer; newer="$(g tag -l 'v*' --sort=-v:refname | head -1)"
  [ "$newer" != "$tag" ] && say "upstream: $newer is a new major: read its garden/docs/MIGRATING.md before taking it"
  local b="garden/$(date +%Y%m%d-%H%M)-upstream-${tag//./-}-root"
  if g for-each-ref --format='%(refname)' 'refs/heads/garden/' | grep -q -- "-upstream-${tag//./-}-root$"; then
    say "upstream: $tag already has a branch: $(g for-each-ref --format='%(refname:short)' 'refs/heads/garden/' | grep -- "-upstream-${tag//./-}-root$")"; return 0
  fi
  if ! has_remote origin && g merge-base --is-ancestor HEAD "$tag"; then
    [ "$DRY" = 1 ] && { say "upstream: would fast-forward to $tag"; return 0; }
    need_clean_default || return 1
    g merge -q --ff-only "$tag" && say "upstream: fast-forwarded to $tag"; return
  fi
  [ "$DRY" = 1 ] && { say "upstream: would stage $tag on $b for a root PR"; return 0; }
  local name; name="$(basename "$R")"
  local T="${XDG_STATE_HOME:-$HOME/.local/state}/garden/$name/stage/${b#garden/}"
  mkdir -p "$(dirname "$T")"
  g worktree add -q "$T" -b "$b" || { say "upstream: could not create the stage $T"; return 1; }
  local msg; msg="$(mktemp)"
  { echo "root: garden $tag"; echo; echo "## Upstream"; echo "noueii/garden $tag, merged on this branch by sync. The owner merges this PR."
    echo; echo "## Changes"; g log --no-merges --format='- %s' "HEAD..$tag" | head -50; } > "$msg"
  if ! git -C "$T" merge -q --no-ff --no-edit "$tag" >/dev/null 2>&1; then
    say "upstream: the merge of $tag has conflicts, in the stage $T:"
    git -C "$T" diff --name-only --diff-filter=U | sed 's/^/  /'
    say "resolve them (garden/skills/sync/ENTRY.md), commit with the message in $msg, then run the staged step"
    return 3
  fi
  git -C "$T" commit -q --amend -F "$msg"; rm -f "$msg"
  if command -v python3 >/dev/null && python3 -c 'import yaml' 2>/dev/null; then
    python3 "$T/garden/check/validate.py" "$T" >/dev/null || {
      say "upstream: $tag merged in $T but the validator fails there: fix it before the staged step"; return 3; }
  fi
  g worktree remove "$T" && say "upstream: staged $tag on $b; the staged step opens its PR"
}

do_decisions() {
  has_remote origin && has_gh || { say "decisions: needs origin and gh, skipped"; return 0; }
  local lines; lines="$(cd "$R" && gh pr list --state closed --limit 100 --json headRefName,title,url,mergedAt \
    --jq '.[] | select(.mergedAt == null) | select(.headRefName | startswith("garden/")) | "\(.title)\t\(.url)"' 2>/dev/null)"
  local t u found=0
  while IFS=$'\t' read -r t u; do
    [ -n "$u" ] || continue
    grep -qF "$u" "$R/memory/rejected.md" 2>/dev/null && continue
    [ "$DRY" = 1 ] && { say "decisions: would record $u"; continue; }
    python3 "$R/garden/skills/memory/write.py" add memory/rejected.md "- $(date +%Y-%m-%d) | ${t//|/-} ($u) | closed without merging" \
      || return 1
    found=$((found + 1))
  done <<< "$lines"
  [ "$found" = 0 ] && say "decisions: no newly closed garden/* PRs" \
    || say "decisions: recorded $found in memory/rejected.md: commit it (memory: rejected proposals) and run the memory step"
  return 0
}

run() { "do_$1"; }
case "$step" in
  status) for s in pull memory upstream staged decisions; do run "$s"; done ;;
  all) for s in pull memory upstream staged decisions; do run "$s"; rc=$?; [ "$rc" = 0 ] || exit "$rc"; done ;;
  *) run "$step" ;;
esac
