#!/usr/bin/env bash
# Fires once per session. Tells UGENT the session_id + cwd + agent so later
# events can be correlated and `/claude` / `/codex` can resolve "current" session.
# Agent detection lives in lib/post_event.sh; PLUGIN_AGENT env overrides it.
set -euo pipefail
exec "$(dirname "$0")/lib/post_event.sh" SessionStart "${PLUGIN_AGENT:-}"
