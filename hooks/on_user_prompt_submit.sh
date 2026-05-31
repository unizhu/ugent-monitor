#!/usr/bin/env bash
set -euo pipefail
agent="${PLUGIN_AGENT:-$( [[ -n "${PLUGIN_ROOT:-}" ]] && echo codex || echo claude-code )}"
exec "$(dirname "$0")/lib/post_event.sh" UserPromptSubmit "$agent"
