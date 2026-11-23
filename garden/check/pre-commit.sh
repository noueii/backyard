#!/usr/bin/env bash
# Optional: enforce the garden's format and budgets on every local commit, memory commits included.
# Install it yourself, once per clone:  ln -s ../../garden/check/pre-commit.sh .git/hooks/pre-commit
# It runs garden/check/validate.py on the working tree and refuses the commit on any error (no truncation, no warning
# and go on): compact or fix first, then commit again.
R="$(git rev-parse --show-toplevel)" || exit 1
if ! python3 -c 'import yaml' 2>/dev/null; then echo "pre-commit: python3 with PyYAML not found; skipped" >&2; exit 0; fi
out="$(python3 "$R/garden/check/validate.py" "$R")" && exit 0
echo "$out" | grep -v '^needs installed' >&2
echo "pre-commit: refused. Fix the errors above (memory over budget: compact it, garden/skills/rsi/retro.md), then commit again." >&2
exit 1
