#!/usr/bin/env bash
# Fires once per session. Tells UGENT the session_id + cwd + agent so later
# events can be correlated and `/claude` / `/codex` can resolve "current" session.
set -euo pipefail
agent="${PLUGIN_AGENT:-$( [[ -n "${PLUGIN_ROOT:-}" && -z "${CLAUDE_PROJECT_DIR:-}" ]] && echo codex || echo claude-code )}"
exec "$(dirname "$0")/lib/post_event.sh" SessionStart "$agent"
