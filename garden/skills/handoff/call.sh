#!/usr/bin/env bash
# Usage: call.sh <tool> <access> <prompt-file> [-- <extra args for the tool>]
#   tool:   claude | pi | omp | opencode   (the tool you are running in)
#   access: read-only | edit | full        (the called seed's `access`)
# Runs the called seed as a fresh, non-interactive session of the same tool, with only the tools its access
# level allows, in the current directory, and prints its final answer. GARDEN_DRY=1 prints the command instead.
#   read-only: read and search files only: no edit, no write, no shell, no sub-agents, no MCP
#   edit:      read-only + edit and write files: still no shell, no sub-agents, no MCP
#   full:      the tool's defaults, under your own permission settings
# What each tool truly enforces is in ENTRY.md ("Access levels"); check.sh is the backstop.
set -euo pipefail

tool="${1:?tool: claude|pi|omp|opencode}"
access="${2:?access: read-only|edit|full}"
prompt_file="${3:?prompt file required}"
shift 3
[ "${1:-}" = "--" ] && shift
[ -r "$prompt_file" ] || { echo "call.sh: cannot read $prompt_file" >&2; exit 2; }
prompt="$(cat "$prompt_file")"
case "$access" in read-only|edit|full) ;; *) echo "call.sh: unknown access: $access" >&2; exit 2 ;; esac

# The called seed reads its SEED.md, docs and memory from the garden, outside the directory it works in.
G="$(cd "$(dirname "$0")/../../.." && pwd -P)"
cmd=()
envs=()
case "$tool" in
  claude)
    # --tools is the allowlist of built-in tools; --strict-mcp-config with no --mcp-config loads no MCP server.
    # -p refuses reads outside the working directory, so the garden gets a read-only allow rule.
    read_garden="{\"permissions\":{\"allow\":[\"Read(/$G/**)\"]}}"
    case "$access" in
      read-only) cmd=(claude -p --tools "Read,Grep,Glob" --strict-mcp-config --permission-mode dontAsk --settings "$read_garden") ;;
      edit) cmd=(claude -p --tools "Read,Grep,Glob,Edit,Write" --strict-mcp-config --permission-mode acceptEdits --settings "$read_garden") ;;
      full) cmd=(claude -p --settings "$read_garden") ;;
    esac ;;
  pi)
    # pi has no permission prompts: --tools is an allowlist over built-in, extension and custom tools.
    case "$access" in
      read-only) cmd=(pi -p --no-session --tools "read,grep,find,ls") ;;
      edit) cmd=(pi -p --no-session --tools "read,grep,find,ls,edit,write") ;;
      full) cmd=(pi -p --no-session) ;;
    esac ;;
  omp)
    case "$access" in
      read-only) cmd=(omp -p --no-session --no-lsp --tools "read,grep,glob") ;;
      edit) cmd=(omp -p --no-session --no-lsp --tools "read,grep,glob,edit,write") ;;
      full) cmd=(omp -p --no-session) ;;
    esac ;;
  opencode)
    # A one-off agent, passed in OPENCODE_CONFIG_CONTENT: every permission denied except the ones listed.
    case "$access" in
      read-only) allow='"read":"allow","grep":"allow","glob":"allow","list":"allow"' ;;
      edit) allow="\"read\":\"allow\",\"grep\":\"allow\",\"glob\":\"allow\",\"list\":\"allow\",\"edit\":\"allow\"" ;;
      full) allow='' ;;
    esac
    if [ "$access" = full ]; then
      envs=("OPENCODE_CONFIG_CONTENT={\"permission\":{\"external_directory\":{\"$G/**\":\"allow\"}}}")
      cmd=(opencode run)
    else
      # external_directory gates paths outside the working directory: only the garden. At edit level that also
      # lets the seed write there (edit patterns could not narrow it), so handoff checks the garden afterwards.
      ext="\"external_directory\":{\"*\":\"deny\",\"$G/**\":\"allow\"}"
      envs=("OPENCODE_CONFIG_CONTENT={\"agent\":{\"garden-$access\":{\"mode\":\"primary\",\"description\":\"garden handoff, access $access\",\"permission\":{\"*\":\"deny\",$allow,$ext}}}}")
      cmd=(opencode run --agent "garden-$access")
    fi ;;
  *) echo "call.sh: unknown tool: $tool" >&2; exit 2 ;;
esac

if [ "${GARDEN_DRY:-}" = 1 ]; then
  printf '%q ' ${envs[@]+"${envs[@]}"} "${cmd[@]}" "$@"; printf '%q\n' "<prompt>"
  exit 0
fi
exec env ${envs[@]+"${envs[@]}"} "${cmd[@]}" "$@" "$prompt" < /dev/null
