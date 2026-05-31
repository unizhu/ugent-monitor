#!/usr/bin/env bash
# Agent detection lives in lib/post_event.sh; PLUGIN_AGENT env overrides it.
set -euo pipefail
exec "$(dirname "$0")/lib/post_event.sh" UserPromptSubmit "${PLUGIN_AGENT:-}"
