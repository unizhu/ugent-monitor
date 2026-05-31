#!/usr/bin/env bash
set -euo pipefail
agent="${PLUGIN_AGENT:-$( [[ -n "${CLAUDE_PLUGIN_ROOT:-}" && -z "${PLUGIN_ROOT:-}" ]] && echo claude-code || echo codex )}"
exec "$(dirname "$0")/lib/post_event.sh" UserPromptSubmit "$agent"
