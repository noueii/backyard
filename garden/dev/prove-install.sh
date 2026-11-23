#!/usr/bin/env bash
# Maintainer-only: the no-AI install proof. In a temp HOME, it installs this repo's HEAD the documented way (a git
# clone over local smart HTTP, then the two symlinks) and checks, for each installed tool:
#   - discovery: pi, omp and opencode list exactly one new skill, `garden` (no model session);
#   - what reaches a model (dev/fake-model.py): `garden` and its description, and no internal skill (memory, rsi,
#     escalate, handoff, sync, new-seed), for Claude Code, pi, omp and opencode;
#   - a seed, a bundled skill and a vendored ENTRY.md add nothing; a nested SKILL.md is ignored by Claude Code, pi
#     and omp, and registered by opencode (why the spec bans it; the probe is removed again);
#   - the optional global line reaches the request;
#   - an update (a commit upstream, then git pull) reaches the next request.
# The real HOME is never touched; no credentials, no network. Tools not installed are skipped with a note.
# Usage: dev/prove-install.sh [--keep] [tool...]
set -uo pipefail
# Ignore a repo chosen by the caller's environment (git sets these in hooks and `rebase -x`): every git call
# here names its repo explicitly.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_NAMESPACE GIT_PREFIX
ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
KEEP=0; [ "${1:-}" = --keep ] && { KEEP=1; shift; }
TOOLS="${*:-claude pi omp opencode}"
T="$(mktemp -d)"; GP=18765; MP=18766
cleanup() { kill "${PIDS[@]}" 2>/dev/null; [ "$KEEP" = 1 ] && echo "kept: $T" || rm -rf "$T"; }
PIDS=(); trap cleanup EXIT
fails=0; pass() { echo "  ok   $*"; }; fail() { echo "  FAIL $*"; fails=$((fails + 1)); }; note() { echo "  --   $*"; }

echo "setup: temp HOME, local git server, fake model"
export HOME="$T/home" XDG_CONFIG_HOME="$T/home/.config" XDG_DATA_HOME="$T/home/.local/share" \
  XDG_CACHE_HOME="$T/home/.cache" XDG_STATE_HOME="$T/home/.local/state"
unset ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN CLAUDE_CODE_OAUTH_TOKEN OPENCODE_CONFIG_CONTENT PI_CODING_AGENT_DIR \
  CLAUDECODE CLAUDE_CODE_ENTRYPOINT
export GIT_AUTHOR_NAME=you GIT_AUTHOR_EMAIL=you@example.com GIT_COMMITTER_NAME=you GIT_COMMITTER_EMAIL=you@example.com
mkdir -p "$HOME/.claude/skills" "$HOME/.agents/skills" "$T/srv/noueii" "$T/req" "$T/work"
for port in $GP $MP; do
  python3 -c "import socket,sys; s=socket.socket(); sys.exit(s.connect_ex(('127.0.0.1', $port)) == 0)" || { echo "port $port is in use"; exit 1; }
done
git clone -q --bare "$ROOT" "$T/srv/noueii/garden.git"
git -C "$T/srv/noueii/garden.git" config http.receivepack true   # anonymous push, localhost only (the update step)
python3 "$ROOT/dev/git-http.py" "$T/srv" --port $GP & PIDS+=($!)
python3 "$ROOT/dev/fake-model.py" "$T/req" --port $MP & PIDS+=($!)
sleep 1
. "$ROOT/dev/fake-providers.sh" "$MP" || exit 1
URL="http://127.0.0.1:$GP/noueii/garden.git"

# What each tool discovers BEFORE the garden is installed: its built-in skills, if any.
pi_skills() { echo '{"type":"get_commands"}' | (cd "$T/work" && timeout 60 pi --mode rpc --no-session --offline 2>/dev/null) | grep -o '"skill:[^"]*"' | sed 's/"skill:\(.*\)"/\1/' | sort -u; }
omp_skills() { (echo '{"type":"get_state"}'; sleep 12) | (cd "$T/work" && ANTHROPIC_API_KEY=dummy timeout 60 omp --mode rpc --no-session --no-title 2>/dev/null) | grep -o '"skill:[^"]*"' | sed 's/"skill:\(.*\)"/\1/' | sort -u; }
opencode_skills() { (cd "$T/work" && timeout 120 opencode debug skill --pure 2>/dev/null) | sed -n 's/^    "name": "\(.*\)",$/\1/p' | sort -u; }
declare -A BASE
for tool in $TOOLS; do
  command -v "$tool" >/dev/null || continue
  case "$tool" in pi|omp|opencode) BASE[$tool]="$("${tool}_skills")" ;; esac
done

echo "install: clone + two symlinks (the README's commands)"
git clone -q "$URL" "$HOME/src/garden" && ln -s "$HOME/src/garden" "$HOME/.agents/skills/garden" \
  && ln -s "$HOME/src/garden" "$HOME/.claude/skills/garden" && pass "installed from $URL" || { fail "install"; exit 1; }
G="$HOME/src/garden"
python3 "$G/check/validate.py" "$G" >/dev/null && pass "the installed garden validates" || fail "the installed garden fails validate.py"

new_skills() { # <tool>: skills listed now that were not listed before the install
  comm -13 <(printf '%s\n' "${BASE[$1]}" | sort -u) <("${1}_skills" | sort -u) | grep -v '^$'
}
discovery() { # <label>
  for tool in pi omp opencode; do
    case " $TOOLS " in *" $tool "*) ;; *) continue ;; esac
    command -v "$tool" >/dev/null || continue
    got="$(new_skills "$tool" | tr '\n' ' ' | sed 's/ $//')"
    [ "$got" = garden ] && pass "$tool discovers exactly one new skill, garden ($1)" || fail "$tool discovers: '$got' ($1)"
  done
}
discovery "fresh install"

DESC="Your bots (seeds) for software work"
model_args() { case "$1" in claude) echo "--model claude-sonnet-4-5" ;; opencode) echo "-m fake/fake-1" ;; *) echo "--model fake/fake-1" ;; esac; }
ask() { # <tool>: one prompt; prints the path of the largest request it sent
  local tool="$1" before; before="$(ls "$T/req" | grep -c '^[0-9]*\.json$')"
  local cmd; case "$tool" in
    claude) cmd=(claude -p) ;; pi) cmd=(pi -p --no-session) ;; omp) cmd=(omp -p --no-session) ;; opencode) cmd=(opencode run --pure) ;;
  esac
  # shellcheck disable=SC2046
  (cd "$T/work" && ANTHROPIC_BASE_URL="http://127.0.0.1:$MP" ANTHROPIC_API_KEY=dummy timeout 180 "${cmd[@]}" $(model_args "$tool") hello \
    < /dev/null > "$T/$tool.out" 2>&1)
  python3 - "$T/req" "$before" <<'PY'
import os, sys
d, n = sys.argv[1], int(sys.argv[2])
new = [int(f[:-5]) for f in os.listdir(d) if f[:-5].isdigit() and int(f[:-5]) > n]
best = max(new, key=lambda f: os.path.getsize(f"{d}/{f}.json"), default=None)
print(f"{d}/{best}.json" if best else "")
PY
}
requests() { # <label> [text that must be in the request] [text that must not]
  local label="$1" must="${2:-}" mustnot="${3:-}"
  for tool in $TOOLS; do
    command -v "$tool" >/dev/null || { note "$tool not installed: skipped"; continue; }
    local req; req="$(ask "$tool")"
    [ -n "$req" ] || { fail "$tool: no request reached the model ($T/$tool.out)"; continue; }
    if grep -qF "$DESC" "$req" && grep -q '\bgarden\b' "$req"; then pass "$tool: garden and its description reach the model ($label)"
    elif [ "$tool" = omp ] && grep -qF -- '- garden: ' "$req"; then
      pass "$tool: garden reaches the model ($label; omp sent a model-rewritten, cached description, here the fake model's)"
    else fail "$tool: garden's description is not in $req ($label)"; fi
    local leak=""
    while IFS= read -r pair; do
      [ -n "$pair" ] || continue
      grep -qF -- "${pair#*:}" "$req" && leak="$leak ${pair%%:*}"
    done <<< "$(printf '%s\n' "memory:Reads and writes the garden's shared" "rsi:Recursive self-improvement: records each run" \
      "escalate:When and how a seed asks the owner" "handoff:Runs another seed: calls it" \
      "sync:Syncs the garden with origin and upstream" "new-seed:Builds, changes or retires a seed")"
    [ -z "$leak" ] && pass "$tool: no internal skill is offered ($label)" || fail "$tool: internal skills offered:$leak ($label)"
    if [ -n "$must" ]; then grep -qF -- "$must" "$req" && pass "$tool: the request has: $must" || fail "$tool: the request lacks: $must"; fi
    if [ -n "$mustnot" ]; then ! grep -qF -- "$mustnot" "$req" && pass "$tool: the request does not have: $mustnot" || note "$tool: the request has: $mustnot"; fi
  done
}
requests "fresh install"

echo "a seed, a bundled skill and a vendored skill add nothing"
FIXTURES="$ROOT/dev/fixtures" bash -c "cd '$G' && . '$ROOT/dev/fixtures/good-seeds.sh'" && git -C "$G" add -A && git -C "$G" commit -qm "two seeds" \
  && python3 "$G/check/validate.py" "$G" >/dev/null && pass "two seeds, a bundled and a vendored skill, valid" || fail "the seeds overlay"
discovery "with seeds"
requests "with seeds" "" "Test-driven development, vendored."

echo "a nested SKILL.md (forbidden by the spec): who registers it"
mkdir -p "$G/seeds/reviewer/skills/nested-probe"
printf -- '---\nname: nested-probe\ndescription: "Nested probe skill. Use when never."\n---\nx\n' > "$G/seeds/reviewer/skills/nested-probe/SKILL.md"
out="$(python3 "$G/check/validate.py" "$G" 2>&1)"
printf '%s' "$out" | grep -q "SKILL.md is only allowed at the root" && pass "the validator rejects it" || fail "the validator accepts it"
for tool in $TOOLS; do
  command -v "$tool" >/dev/null || continue
  req="$(ask "$tool")"
  if grep -qF "Nested probe skill" "$req"; then note "$tool registers a nested SKILL.md as another skill"
  else note "$tool ignores a nested SKILL.md"; fi
done
rm -rf "$G/seeds/reviewer/skills/nested-probe"

echo "the optional global line"
LINE="Start every task with the garden skill, unless your prompt says you were called as a seed inside a running task."
printf '%s\n' "$LINE" | tee -a "$HOME/.claude/CLAUDE.md" "$HOME/.pi/agent/AGENTS.md" "$HOME/.omp/agent/AGENTS.md" \
  "$XDG_CONFIG_HOME/opencode/AGENTS.md" > /dev/null
requests "with the global line" "$LINE"

echo "an update: a commit upstream, then git pull"
U="$T/upstream-work"; git clone -q "$URL" "$U"
sed -i 's/^description: "Your bots (seeds) for software work\./description: "Your bots (seeds) for software work. Update probe 42./' "$U/SKILL.md"
git -C "$U" commit -qam "router: update probe" && git -C "$U" push -q origin HEAD && pass "an update is pushed upstream" || fail "push the update"
git -C "$G" pull -q --rebase && pass "git pull --rebase took the update (and kept the local seeds commit)" || fail "git pull"
requests "after the update" "Update probe 42."

echo
if [ "$fails" = 0 ]; then echo "prove-install: all passed"; else echo "prove-install: $fails failed"; exit 1; fi
