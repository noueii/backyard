# Maintainer-only, sourced by the proofs: points pi, omp and opencode at garden/dev/fake-model.py (provider "fake",
# model "fake-1") in the CURRENT (temp) HOME. Claude Code needs only ANTHROPIC_BASE_URL and ANTHROPIC_API_KEY.
# Usage: . garden/dev/fake-providers.sh <port>
_mp="${1:?port}"
case "$HOME" in /tmp/*|"${TMPDIR:-/tmp}"/*) ;; *) echo "fake-providers.sh: HOME is not a temp dir: $HOME" >&2; return 1 ;; esac
mkdir -p "$HOME/.pi/agent" "$HOME/.omp/agent" "${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
printf '%s\n' '{ "providers": { "fake": { "baseUrl": "http://127.0.0.1:'"$_mp"'/v1", "api": "openai-completions",
  "apiKey": "dummy", "compat": { "supportsDeveloperRole": false, "supportsReasoningEffort": false },
  "models": [{ "id": "fake-1" }] } } }' > "$HOME/.pi/agent/models.json"
printf '%s\n' 'providers:' \
  '  fake: { baseUrl: "http://127.0.0.1:'"$_mp"'/v1", api: openai-completions, apiKey: dummy,' \
  '          compat: { supportsDeveloperRole: false, supportsReasoningEffort: false }, models: [{ id: fake-1 }] }' \
  > "$HOME/.omp/agent/models.yml"
printf '%s\n' '{ "$schema": "https://opencode.ai/config.json", "autoupdate": false, "share": "disabled",
  "provider": { "fake": { "npm": "@ai-sdk/openai-compatible", "name": "fake", "models": { "fake-1": {} },
  "options": { "baseURL": "http://127.0.0.1:'"$_mp"'/v1", "apiKey": "dummy" } } } }' \
  > "${XDG_CONFIG_HOME:-$HOME/.config}/opencode/opencode.json"
unset _mp
