# UGENT Monitor Plugin

A monitoring plugin for Claude Code and Codex that reports session lifecycle events to UGENT for rate-limit-aware auto-resume capabilities.

## Features

- **Session Tracking**: Reports when Claude Code or Codex sessions start and stop
- **Rate Limit Detection**: Detects when sessions hit rate limits and reports retry timing
- **Auto-Resume Support**: Enables UGENT to automatically resume sessions after rate limits reset
- **Tool Usage Monitoring**: Tracks tool usage events for better observability

## Installation

### Claude Code

```bash
# Add the marketplace
/plugin marketplace add unizhu/ugent-monitor

# Install the plugin
/plugin install ugent-monitor@ugent-monitor
```

### Codex

```bash
# Add the marketplace
codex plugin marketplace add unizhu/ugent-monitor

# Install the plugin
codex plugin install ugent-monitor@ugent-monitor
```

**Important: Codex Hooks Workaround**

Codex has a known bug ([issue #16430](https://github.com/openai/codex/issues/16430)) where plugin-local hooks don't execute. The runtime only loads hooks from `~/.codex/hooks.json`, not from plugin directories.

**Workaround**: After installing the plugin, manually copy the hooks configuration:

```bash
# Find the plugin installation directory
PLUGIN_DIR=$(find ~/.codex/plugins -name "ugent-monitor" -type d | head -1)

# Copy hooks.json to the global location
cp "$PLUGIN_DIR/hooks/hooks.json" ~/.codex/hooks.json

# Make hook scripts executable
chmod +x "$PLUGIN_DIR"/hooks/*.sh
chmod +x "$PLUGIN_DIR"/hooks/lib/*.sh
```

Then restart Codex for the hooks to take effect.

## How It Works

The plugin uses lifecycle hooks to send JSON-RPC events to UGENT's plugin bridge:

1. **SessionStart**: Fired when a new session begins
2. **UserPromptSubmit**: Fired when the user submits a prompt
3. **Stop**: Fired when the session stops (including rate limit stops)
4. **PostToolUse**: Fired after each tool execution

Each hook script:
- Collects session metadata (session ID, agent type, timestamp)
- Sends a JSON-RPC `external_agent.report_event` request to UGENT
- UGENT's `ExternalSessionRegistry` tracks the session state
- The `ResumeScheduler` monitors rate-limited sessions and triggers auto-resume

## Configuration

The plugin automatically detects:
- **Agent Type**: Claude Code vs Codex (via environment variables)
- **Session ID**: From `CLAUDE_SESSION_ID` or `CODEX_SESSION_ID`
- **Rate Limit Info**: From `RETRY_AFTER` environment variable (if set)

No manual configuration is required.

## Requirements

- UGENT running with plugin bridge enabled
- Claude Code or Codex CLI installed
- Bash shell (for hook scripts)
- `curl` and `jq` (for JSON-RPC communication)

## Directory Structure

```
ugent-monitor/
├── .claude-plugin/
│   ├── marketplace.json    # Claude Code marketplace manifest
│   └── plugin.json         # Claude Code plugin manifest
├── .codex-plugin/
│   └── plugin.json         # Codex plugin manifest
├── .agents/
│   └── plugins/
│       └── marketplace.json # Codex marketplace manifest
├── hooks/
│   ├── hooks.json          # Codex hooks configuration
│   ├── on_session_start.sh
│   ├── on_user_prompt_submit.sh
│   ├── on_stop.sh
│   ├── on_post_tool_use.sh
│   └── lib/
│       └── post_event.sh   # Shared JSON-RPC helper
└── commands/
    └── ugent-resume.md     # Custom command for manual resume
```

## Troubleshooting

### Claude Code: "source type not supported"

This error occurs with older marketplace configurations. The latest version uses `"source": "./"` which is compatible with all Claude Code versions.

**Solution**: Remove and re-add the marketplace:
```bash
/plugin marketplace remove ugent-monitor
/plugin marketplace add unizhu/ugent-monitor
/plugin install ugent-monitor@ugent-monitor
```

### Codex: "No plugin hooks"

This is the known bug mentioned above. Plugin-local hooks don't work in Codex.

**Solution**: Use the workaround to copy hooks to `~/.codex/hooks.json`.

### Hooks Not Firing

1. Check that UGENT is running: `ps aux | grep ugent`
2. Verify the plugin bridge socket exists: `ls -la ~/.ugent/run/bridge.sock`
3. Check hook script permissions: `chmod +x hooks/*.sh hooks/lib/*.sh`
4. Test a hook manually: `./hooks/on_session_start.sh`

### Rate Limit Auto-Resume Not Working

1. Verify the session is tracked: In UGENT REPL, run `/claude status` or `/codex status`
2. Check that `auto_resume_enabled = true` in `~/.ugent/external_agents.toml`
3. For yolo mode, also set `auto_resume_allow_yolo = true`
4. Check UGENT logs for scheduler activity

## License

MIT License - Copyright 2026 Uni Zhu

## Links

- [UGENT Project](https://github.com/unizhu/ugent)
- [Claude Code Plugins Docs](https://code.claude.com/docs/en/plugins)
- [Codex Plugins Docs](https://developers.openai.com/codex/plugins)
- [Codex Hooks Bug #16430](https://github.com/openai/codex/issues/16430)
