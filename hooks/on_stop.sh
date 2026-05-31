#!/usr/bin/env bash
# The agent has stopped its turn. UGENT inspects the JSON for rate-limit signals.
# We do NOT block stop here (no `decision: block` returned) — auto-resume is
# scheduler-driven in UGENT, not hook-driven, so the user's stop intent is honored.
set -euo pipefail
agent="${PLUGIN_AGENT:-$( [[ -n "${CLAUDE_PLUGIN_ROOT:-}" && -z "${PLUGIN_ROOT:-}" ]] && echo claude-code || echo codex )}"
exec "$(dirname "$0")/lib/post_event.sh" Stop "$agent"
