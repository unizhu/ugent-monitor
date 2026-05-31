#!/usr/bin/env bash
# Shared helper: read raw hook JSON from stdin, wrap with metadata, POST to UGENT IPC.
# Usage:  post_event.sh <event_name> <agent>
# Env:    UGENT_BRIDGE_SOCK   Override default socket path
#         UGENT_BRIDGE_HTTP   Override HTTP endpoint URL
#         UGENT_IPC_TOKEN     Pre-shared token, contents of ~/.ugent/run/external_agent_token
#
# Socket resolution order:
#   1. $UGENT_BRIDGE_SOCK (explicit pin)
#   2. Workspace walk: $PWD -> parent -> ... -> /, looking for .ugent/run/bridge.sock
#   3. Global instance registry: longest workspace_root prefix match, tiebreak by heartbeat
#   4. Single-instance fallback: ~/.ugent/run/bridge.sock
#   5. HTTP fallback from instance registry (Windows)

set -euo pipefail

event_name="${1:?event name required}"
agent="${2:?agent required (claude-code|codex)}"

resolve_socket() {
  # 1. Explicit pin
  if [[ -n "${UGENT_BRIDGE_SOCK:-}" && -S "${UGENT_BRIDGE_SOCK}" ]]; then
    echo "$UGENT_BRIDGE_SOCK"; return 0
  fi

  # 2. Workspace walk
  local d="$PWD"
  while [[ "$d" != "/" && -n "$d" ]]; do
    if [[ -S "$d/.ugent/run/bridge.sock" ]]; then
      echo "$d/.ugent/run/bridge.sock"; return 0
    fi
    d=$(dirname "$d")
  done

  # 3. Global instance registry (longest prefix match, tiebreak by heartbeat)
  local idx="$HOME/.ugent/run/instances.json"
  if [[ -r "$idx" ]] && command -v jq >/dev/null 2>&1; then
    local sock
    sock=$(jq -r --arg cwd "$PWD" '
      .instances
      | map(select($cwd | startswith(.workspace_root)))
      | sort_by(.workspace_root | length) | reverse
      | sort_by(.last_heartbeat) | reverse
      | first | .socket // empty
    ' "$idx" 2>/dev/null || true)
    if [[ -n "$sock" && -S "$sock" ]]; then echo "$sock"; return 0; fi

    # 3b. HTTP fallback from registry (Windows)
    local http_url
    http_url=$(jq -r --arg cwd "$PWD" '
      .instances
      | map(select($cwd | startswith(.workspace_root)))
      | sort_by(.workspace_root | length) | reverse
      | sort_by(.last_heartbeat) | reverse
      | first | .http_url // empty
    ' "$idx" 2>/dev/null || true)
    if [[ -n "$http_url" ]]; then echo "HTTP:$http_url"; return 0; fi
  fi

  # 4. Single-instance fallback
  if [[ -S "$HOME/.ugent/run/bridge.sock" ]]; then
    echo "$HOME/.ugent/run/bridge.sock"; return 0
  fi

  # 5. HTTP fallback from env
  if [[ -n "${UGENT_BRIDGE_HTTP:-}" ]]; then
    echo "HTTP:${UGENT_BRIDGE_HTTP}"; return 0
  fi

  return 1
}

raw=$(cat)
target=$(resolve_socket) || exit 0  # UGENT not running: fail silently

token_path="${UGENT_IPC_TOKEN_PATH:-$HOME/.ugent/run/external_agent_token}"
token=""
if [[ -r "$token_path" ]]; then
  token="$(cat "$token_path")"
fi

if command -v jq >/dev/null 2>&1; then
  payload=$(jq -nc \
    --arg method "external_agent.report_event" \
    --arg agent "$agent" \
    --arg event "$event_name" \
    --arg cwd "$PWD" \
    --argjson raw "$raw" \
    '{jsonrpc:"2.0", id:1, method:$method,
      params:{agent:$agent, event:$event, cwd:$cwd, raw:$raw}}')
else
  payload=$(printf '{"jsonrpc":"2.0","id":1,"method":"external_agent.report_event","params":{"agent":"%s","event":"%s","cwd":"%s","raw":%s}}' \
    "$agent" "$event_name" "$PWD" "$raw")
fi

if [[ "$target" == HTTP:* ]]; then
  http_url="${target#HTTP:}"
  curl --silent --show-error --max-time 5 \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${token}" \
    -X POST "$http_url/rpc" \
    -d "$payload" >/dev/null 2>&1 || true
else
  curl --silent --show-error --max-time 5 --unix-socket "$target" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${token}" \
    -X POST "http://localhost/rpc" \
    -d "$payload" >/dev/null 2>&1 || true
fi
