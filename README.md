# ugent-monitor

Plugin for Claude Code and Codex that reports session lifecycle events to UGENT.
Used by UGENT to auto-resume rate-limited sessions after the cooldown elapses.

## Install (Claude Code)

```bash
# Add this repo as a local marketplace
/plugin marketplace add /Users/unizhu/Documents/AI/ugent-monitor

# Install the plugin from the marketplace
/plugin install ugent-monitor@ugent-monitor
```

Or clone and use a local marketplace entry pointing at this repo.

## Install (Codex)

```bash
# Add this repo as a local marketplace
codex marketplace add /Users/unizhu/Documents/AI/ugent-monitor

# Then in Codex:
/plugins
# Select "UGENT Monitor" marketplace, install ugent-monitor
```

**Known issue:** Codex <= v0.118.0 has a bug where plugin-local hooks may not
execute even though the manifest correctly references `./hooks/hooks.json`
(see [openai/codex#16430](https://github.com/openai/codex/issues/16430)).
If hooks do not fire after installing, manually copy the hook definitions:

```bash
cp ~/.codex/plugins/cache/*/ugent-monitor/local/hooks/hooks.json ~/.codex/hooks.json
```

Then restart Codex.

## Requirements

- UGENT >= 0.x running locally with the plugin IPC bridge active.
- `curl`, `jq`, `bash` on PATH.

## Cross-platform

- macOS / Linux: works out of the box (bash + curl + jq).
- Windows: requires Git Bash on PATH and `jq` (`winget install jqlang.jq`).
  Hooks fall back to localhost HTTP if no Unix socket is found.
- WSL: works identically to Linux when UGENT runs inside the same distro.

## Hook Events

| Event | When it fires | Purpose |
|-------|---------------|---------|
| `SessionStart` | Session begins or resumes | Registers session_id + cwd with UGENT |
| `UserPromptSubmit` | User submits a prompt | Tracks user activity for resume backoff |
| `Stop` | Agent stops its turn | Detects rate-limit signals in JSON payload |
| `PostToolUse` | After any tool call | Optional monitoring |

## Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `UGENT_BRIDGE_SOCK` | auto-detect | Override default Unix socket path |
| `UGENT_BRIDGE_HTTP` | none | Override HTTP endpoint URL (Windows) |
| `UGENT_IPC_TOKEN_PATH` | `~/.ugent/run/external_agent_token` | Token file location |
| `PLUGIN_AGENT` | auto-detect | Force agent type: `claude-code` or `codex` |

Agent detection: `PLUGIN_ROOT` set means Codex; otherwise Claude Code.

## Socket Resolution Order

1. `$UGENT_BRIDGE_SOCK` (explicit pin)
2. Workspace walk: `$PWD -> parent -> ... -> /` looking for `.ugent/run/bridge.sock`
3. Global instance registry: longest workspace prefix match, tiebreak by heartbeat
4. Single-instance fallback: `~/.ugent/run/bridge.sock`
5. HTTP fallback from `$UGENT_BRIDGE_HTTP` or instance registry

## License

MIT
