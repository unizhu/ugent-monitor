#!/usr/bin/env bash
# The agent has stopped its turn. UGENT inspects the JSON for rate-limit signals.
# We do NOT block stop here (no `decision: block` returned) -- auto-resume is
# scheduler-driven in UGENT, not hook-driven, so the user's stop intent is honored.
# Agent detection lives in lib/post_event.sh; PLUGIN_AGENT env overrides it.
set -euo pipefail
exec "$(dirname "$0")/lib/post_event.sh" Stop "${PLUGIN_AGENT:-}"
