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

**Important:** Codex v0.118.0 has a known issue where plugin-local hooks may not run
(see [openai/codex#16430](https://github.com/openai/codex/issues/16430)). If hooks
don't fire, manually copy `hooks/hooks.json` to `~/.codex/hooks.json`:

```bash
cp ~/.codex/plugins/cache/*/ugent-monitor/hooks/hooks.json ~/.codex/hooks.json
```

## Requirements

UGENT >= 0.x (running locally with the plugin IPC bridge active).

## Cross-platform

- macOS / Linux: works out of the box (bash + curl + jq).
- Windows: requires Git Bash on PATH and `jq` (`winget install jqlang.jq`).
  Hooks fall back to localhost HTTP if no Unix socket is found.
- WSL: works identically to Linux when UGENT runs inside the same distro.

## Hook Events

| Event | When it fires | Purpose |
|-------|---------------|---------|
| `SessionStart` | Session begins or resumes | Registers session with UGENT |
| `UserPromptSubmit` | User submits a prompt | Tracks user activity for backoff |
| `Stop` | Agent stops its turn | Detects rate-limit signals |
| `PostToolUse` | After any tool call | Optional: track tool usage patterns |

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `UGENT_BRIDGE_SOCK` | Override default socket path |
| `UGENT_BRIDGE_HTTP` | Override HTTP endpoint URL (Windows) |
| `UGENT_IPC_TOKEN_PATH` | Override token file location |
| `PLUGIN_AGENT` | Force agent type (claude-code or codex) |
