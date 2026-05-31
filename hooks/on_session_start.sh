#!/usr/bin/env bash
# Fires once per session. Tells UGENT the session_id + cwd + agent so later
# events can be correlated and `/claude` / `/codex` can resolve "current" session.
set -euo pipefail
agent="${PLUGIN_AGENT:-$( [[ -n "${CLAUDE_PLUGIN_ROOT:-}" && -z "${PLUGIN_ROOT:-}" ]] && echo claude-code || echo codex )}"
exec "$(dirname "$0")/lib/post_event.sh" SessionStart "$agent"
