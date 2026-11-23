#!/usr/bin/env bash
# Maintainer-only: proves what skills/handoff/call.sh really enforces per tool and access level. No AI runs.
# For each installed tool (claude, pi, omp, opencode) and each level (read-only, edit, full), in a temp HOME and
# against dev/fake-model.py, it runs call.sh three times. The fake model answers the first turn with one tool call:
#   - "offered": a harmless turn; the request's tool list is compared with the level's allowlist;
#   - "write":   a call to the tool's write tool, creating a file;
#   - "shell":   a call to the tool's shell tool, running `touch`;
# A call to a tool that the request did not offer is still made: the tool must refuse it.
#   - "read":    a call to the read tool on a file OUTSIDE the working directory (a called seed reads its SEED.md
#                from the garden while it works in a project): its content must reach the model;
# Then it checks the file system: what the level forbids must not exist. Tools not installed are skipped.
# Usage: dev/prove-access.sh [--keep] [tool...]
set -uo pipefail
# Ignore a repo chosen by the caller's environment (git sets these in hooks and `rebase -x`): every git call
# here names its repo explicitly.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_NAMESPACE GIT_PREFIX
ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
KEEP=0; [ "${1:-}" = --keep ] && { KEEP=1; shift; }
TOOLS="${*:-claude pi omp opencode}"
T="$(mktemp -d)"; MP=18866
cleanup() { kill "${PIDS[@]}" 2>/dev/null; [ "$KEEP" = 1 ] && echo "kept: $T" || rm -rf "$T"; }
PIDS=(); trap cleanup EXIT
fails=0; pass() { echo "  ok   $*"; }; fail() { echo "  FAIL $*"; fails=$((fails + 1)); }; note() { echo "  --   $*"; }

real_home="$HOME"
export HOME="$T/home" XDG_CONFIG_HOME="$T/home/.config" XDG_DATA_HOME="$T/home/.local/share" \
  XDG_CACHE_HOME="$T/home/.cache" XDG_STATE_HOME="$T/home/.local/state"
unset ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN CLAUDE_CODE_OAUTH_TOKEN OPENCODE_CONFIG_CONTENT PI_CODING_AGENT_DIR \
  CLAUDECODE CLAUDE_CODE_ENTRYPOINT
mkdir -p "$HOME/.pi/agent" "$HOME/.omp/agent" "$XDG_CONFIG_HOME/opencode" "$T/req" "$T/work"
python3 -c "import socket,sys; s=socket.socket(); sys.exit(s.connect_ex(('127.0.0.1', $MP)) == 0)" || { echo "port $MP is in use"; exit 1; }
python3 "$ROOT/dev/fake-model.py" "$T/req" --port $MP & PIDS+=($!)
sleep 1
. "$ROOT/dev/fake-providers.sh" "$MP"
[ "$HOME" != "$real_home" ] || exit 1
# call.sh runs from a garden copy, so the garden it lets the called seed read is $T/garden, outside each work dir
mkdir -p "$T/garden/skills/handoff" && cp "$ROOT/skills/handoff/call.sh" "$T/garden/skills/handoff/"

# The tools each level may offer (lower-cased). Anything else offered is a failure.
allowed() { # <tool> <level>
  case "$1:$2" in
    claude:read-only) echo "read grep glob" ;;
    claude:edit) echo "read grep glob edit write" ;;
    pi:read-only) echo "read grep find ls" ;;
    pi:edit) echo "read grep find ls edit write" ;;
    omp:read-only) echo "read grep glob" ;;
    omp:edit) echo "read grep glob edit write" ;;
    opencode:read-only) echo "read grep glob list" ;;
    opencode:edit) echo "read grep glob list edit write apply_patch" ;;
    *) echo "*" ;;
  esac
}
names() { # <tool>: write, shell and read tool names
  case "$1" in claude) echo "Write Bash Read" ;; *) echo "write bash read" ;; esac
}
model_args() {
  case "$1" in
    claude) echo "--model claude-sonnet-4-5" ;;
    opencode) echo "-m fake/fake-1" ;;
    *) echo "--model fake/fake-1" ;;
  esac
}

run() { # <tool> <level> <probe>: runs call.sh in a fresh work dir; prints the work dir
  local tool="$1" level="$2" probe="$3" w="$T/work/$1-$2-$3"
  mkdir -p "$w"
  read -r wname sname rname <<< "$(names "$tool")"
  case "$probe" in
    offered) rm -f "$T/req/probe.json" ;;
    write) printf '{"names":["%s"],"path":"%s/written.txt","content":"x"}' "$wname" "$w" > "$T/req/probe.json" ;;
    shell) printf '{"names":["%s"],"command":"touch %s/shell-ran"}' "$sname" "$w" > "$T/req/probe.json" ;;
    write-garden) printf '{"names":["%s"],"path":"%s/garden/seeds/x/written.txt","content":"x"}' "$wname" "$T" > "$T/req/probe.json" ;;
    read) mkdir -p "$T/garden/seeds/x"; echo "GARDEN-MARKER-$tool-$level" > "$T/garden/seeds/x/SEED.md"
          printf '{"names":["%s"],"path":"%s/garden/seeds/x/SEED.md"}' "$rname" "$T" > "$T/req/probe.json" ;;
  esac
  echo "Say ok." > "$T/prompt.md"
  local before; before="$(ls "$T/req" | grep -c '^[0-9]*\.json$')"
  # shellcheck disable=SC2046
  (cd "$w" && ANTHROPIC_BASE_URL="http://127.0.0.1:$MP" ANTHROPIC_API_KEY=dummy \
     timeout 180 bash "$T/garden/skills/handoff/call.sh" "$tool" "$level" "$T/prompt.md" -- $(model_args "$tool") \
     > "$w.out" 2>&1)
  echo "$before" > "$w.before"
}

offered_tools() { # <before-count>: the tool names of the largest request since then, lower-cased
  python3 - "$T/req" "$1" <<'PY'
import json, os, sys
d, n = sys.argv[1], int(sys.argv[2])
new = [int(f[:-5]) for f in os.listdir(d) if f[:-5].isdigit() and int(f[:-5]) > n]
best, names = None, []
for f in new:
    b = json.load(open(f"{d}/{f}.json"))["body"]
    t = [x.get("function", x).get("name", "") for x in b.get("tools") or []]
    if len(t) > len(names): names = t
print(" ".join(sorted(x.lower() for x in names)))
PY
}

for tool in $TOOLS; do
  if ! command -v "$tool" >/dev/null; then note "$tool not installed: skipped"; continue; fi
  echo "$tool $("$tool" --version 2>&1 | head -1)"
  for level in read-only edit full; do
    run "$tool" "$level" offered
    w="$T/work/$tool-$level-offered"
    got="$(offered_tools "$(cat "$w.before")")"
    if [ -z "$got" ]; then fail "$tool $level: no request with tools reached the model ($w.out)"; continue; fi
    want="$(allowed "$tool" "$level")"
    if [ "$want" = "*" ]; then
      note "$tool $level offers: $got"
    else
      extra=""; for t in $got; do case " $want " in *" $t "*) ;; *) extra="$extra $t" ;; esac; done
      [ -z "$extra" ] && pass "$tool $level offers only: $got" || fail "$tool $level also offers:$extra"
    fi

    run "$tool" "$level" write; w="$T/work/$tool-$level-write"
    if [ -e "$w/written.txt" ]; then
      [ "$level" = read-only ] && fail "$tool $level: the write tool ran" || pass "$tool $level: the write tool ran"
    else
      case "$level" in
        read-only) pass "$tool $level: the write tool was refused" ;;
        edit) fail "$tool $level: the write tool did not run ($w.out)" ;;
        full) note "$tool $level: the write tool did not run without approval (your permission settings decide)" ;;
      esac
    fi

    run "$tool" "$level" shell; w="$T/work/$tool-$level-shell"
    if [ -e "$w/shell-ran" ]; then
      [ "$level" = full ] && pass "$tool $level: the shell ran" || fail "$tool $level: the shell ran"
    else
      [ "$level" = full ] && note "$tool $level: the shell did not run without approval (your permission settings decide)" \
        || pass "$tool $level: the shell was refused"
    fi

    if [ "$level" = edit ]; then
      rm -f "$T/garden/seeds/x/written.txt"; run "$tool" "$level" write-garden
      if [ -e "$T/garden/seeds/x/written.txt" ]; then
        note "$tool edit: can also write outside the working directory (the garden itself): checked afterwards only"
      else
        pass "$tool edit: writing outside the working directory (the garden itself) was refused"
      fi
    fi

    run "$tool" "$level" read; w="$T/work/$tool-$level-read"
    if grep -lq "GARDEN-MARKER-$tool-$level" $(ls -d "$T"/req/[0-9]*.json | awk -F/ -v n="$(cat "$w.before")" '{f=$NF; sub(/\.json$/,"",f); if (f+0>n) print}') /dev/null; then
      pass "$tool $level: a file outside the working directory can be read"
    else
      fail "$tool $level: reading a file outside the working directory failed ($w.out)"
    fi
  done
done

echo
if [ "$fails" = 0 ]; then echo "prove-access: all passed"; else echo "prove-access: $fails failed"; exit 1; fi
