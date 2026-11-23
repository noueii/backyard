#!/usr/bin/env bash
# The backstop for access levels: a git snapshot before a call, and a check after it.
# Usage: check.sh snapshot [dir]                  prints a token (HEAD, refs and a tree of the working directory)
#        check.sh verify <access> <token> [dir]   compares now with the token; exit 1 on a violation
# The tree includes untracked files (not ignored ones) and is built with a temporary index, so the snapshot
# never touches your index, working tree, stash or refs.
#   read-only: any change to files, HEAD or refs is a violation
#   edit:      file changes are allowed; a change to HEAD or refs (a commit, a branch: only a shell can do that)
#              is a violation
#   full:      nothing is a violation; the changes are listed
set -euo pipefail
# Ignore a repo chosen by the caller's environment (git sets these in hooks and `rebase -x`): every git call
# here names its repo explicitly.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_NAMESPACE GIT_PREFIX
cmd="${1:?snapshot | verify}"; shift
die() { echo "check.sh: $*" >&2; exit 2; }

state() { # <dir>: HEAD:refs-hash:tree
  local d="$1" idx head refs tree
  git -C "$d" rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "$d is not in a git work tree"
  idx="$(mktemp)"; trap 'rm -f "$idx" "$idx.lock"' RETURN
  local gi; gi="$(git -C "$d" rev-parse --git-path index)"; case "$gi" in /*) ;; *) gi="$d/$gi" ;; esac
  [ -f "$gi" ] && cp "$gi" "$idx" || rm -f "$idx"
  head="$(git -C "$d" rev-parse -q --verify HEAD || echo none)"
  refs="$(git -C "$d" for-each-ref --format='%(refname) %(objectname)' | git hash-object --stdin)"
  ( cd "$(git -C "$d" rev-parse --show-toplevel)" && GIT_INDEX_FILE="$idx" git add -A . >/dev/null 2>&1 )
  tree="$(cd "$(git -C "$d" rev-parse --show-toplevel)" && GIT_INDEX_FILE="$idx" git write-tree)"
  echo "$head:$refs:$tree"
}

case "$cmd" in
  snapshot)
    state "${1:-.}" ;;
  verify)
    access="${1:?access: read-only | edit | full}"; token="${2:?token from check.sh snapshot}"; d="${3:-.}"
    case "$access" in read-only|edit|full) ;; *) die "unknown access: $access" ;; esac
    IFS=: read -r head0 refs0 tree0 <<< "$token"
    [ -n "${tree0:-}" ] || die "not a token from check.sh snapshot: $token"
    IFS=: read -r head1 refs1 tree1 <<< "$(state "$d")"
    files="$(cd "$(git -C "$d" rev-parse --show-toplevel)" && git diff --name-status "$tree0" "$tree1")"
    n="$(printf '%s' "$files" | grep -c . || true)"
    git_changed=""
    [ "$head0" = "$head1" ] || git_changed="HEAD moved ($head0 -> $head1)"
    [ "$refs0" = "$refs1" ] || git_changed="${git_changed:+$git_changed; }branches or tags changed"
    bad=""
    case "$access" in
      read-only) [ -n "$files" ] || [ -n "$git_changed" ] && bad=1 ;;
      edit) [ -n "$git_changed" ] && bad=1 ;;
    esac
    if [ -n "$bad" ]; then
      echo "ACCESS VIOLATION (access: $access):"
      [ -n "$git_changed" ] && echo "  git: $git_changed"
      [ -n "$files" ] && printf '%s\n' "$files" | sed 's/^/  /'
      exit 1
    fi
    echo "ok: access $access kept ($n file(s) changed${git_changed:+; $git_changed})"
    [ -n "$files" ] && printf '%s\n' "$files" | sed 's/^/  /'
    exit 0 ;;
  *) die "unknown command: $cmd (snapshot | verify)" ;;
esac
