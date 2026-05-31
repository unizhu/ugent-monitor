# ugent-monitor

Plugin for Claude Code and Codex that reports session lifecycle events to UGENT.
Used by UGENT to auto-resume rate-limited sessions after the cooldown elapses.

## Install (Claude Code)

```
/plugin marketplace add unizhu/ugent-monitor
/plugin install ugent-monitor@unizhu-ugent-monitor
```

## Install (Codex)

```
codex
/plugins
# Add unizhu/ugent-monitor marketplace, install ugent-monitor
```

## Requirements

UGENT >= 0.x (running locally with the plugin IPC bridge active).

## Cross-platform

- macOS / Linux: works out of the box (bash + curl + jq).
- Windows: requires Git Bash on PATH and `jq` (`winget install jqlang.jq`).
  Hooks fall back to localhost HTTP if no Unix socket is found.
- WSL: works identically to Linux when UGENT runs inside the same distro.
