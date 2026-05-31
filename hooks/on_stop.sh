#!/usr/bin/env bash
# The agent has stopped its turn. UGENT inspects the JSON for rate-limit signals.
# We do NOT block stop here (no `decision: block` returned) — auto-resume is
# scheduler-driven in UGENT, not hook-driven, so the user's stop intent is honored.
set -euo pipefail
agent="${PLUGIN_AGENT:-$( [[ -n "${PLUGIN_ROOT:-}" ]] && echo codex || echo claude-code )}"
exec "$(dirname "$0")/lib/post_event.sh" Stop "$agent"
