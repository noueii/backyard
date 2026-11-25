#!/usr/bin/env bash
# Usage: block.sh --kind escalation|review|question|route --seed <name|backyard> --question "<one question>" \
#                 --why "<why docs and memory can't settle it>" [--option "<recommended>" --option ...]
# Prints the fixed block that asks the owner. Put it at the end of your message and stop.
# Refuses an empty or multi-line field, an unknown kind, a question with more than one "?", and more than 4 options.
set -uo pipefail
kind="" seed="" question="" why="" options=()
die() { echo "block.sh: $*" >&2; exit 2; }
while [ $# -gt 0 ]; do
  [ $# -ge 2 ] || die "$1 needs a value"
  case "$1" in
    --kind) kind="$2" ;; --seed) seed="$2" ;; --question) question="$2" ;; --why) why="$2" ;;
    --option) options+=("$2") ;;
    *) die "unknown argument: $1" ;;
  esac
  shift 2
done
case "$kind" in escalation|review|question|route) ;; *) die "--kind is escalation, review, question or route" ;; esac
for f in seed question why; do
  v="${!f}"
  [ -n "${v// /}" ] || die "--$f is empty"
  case "$v" in *$'\n'*) die "--$f must be one line" ;; esac
done
printf '%s' "$seed" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$' || die "--seed is a seed name (or backyard, for the router)"
q="${question//[^?]/}"; [ "${#q}" -le 1 ] || die "--question holds ONE question (it has ${#q} question marks)"
[ "${#options[@]}" -le 4 ] || die "at most 4 options"
for o in ${options[@]+"${options[@]}"}; do
  [ -n "${o// /}" ] || die "an --option is empty"
  case "$o" in *$'\n'*) die "an --option must be one line" ;; esac
done
echo "<<<SEED"
echo "kind: $kind"
echo "seed: $seed"
echo "question: $question"
echo "why: $why"
if [ "${#options[@]}" -gt 0 ]; then
  out=""; for i in "${!options[@]}"; do
    o="\"${options[$i]//\"/\\\"}\""; [ "$i" = 0 ] && o="$o (recommended)"
    out="${out:+$out, }$o"
  done
  echo "options: [$out]"
fi
echo ">>>"
