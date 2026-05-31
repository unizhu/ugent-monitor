# UGENT Monitor Plugin Marketplace

This repository contains the UGENT Monitor plugin for Claude Code and Codex. The plugin reports session lifecycle events to UGENT for rate-limit-aware auto-resume capabilities.

## Installation

### Claude Code

```bash
# Add this repository as a marketplace
/plugin marketplace add https://github.com/unizhu/ugent-monitor

# Install the plugin
/plugin install ugent-monitor@ugent-monitor
```

### Codex

```bash
# Add this repository as a marketplace
codex marketplace add https://github.com/unizhu/ugent-monitor

# List available plugins
/plugins
```

Then select "UGENT Monitor" from the marketplace and install it.

## Plugin Features

The ugent-monitor plugin provides:

- **SessionStart hook**: Reports when a session begins
- **UserPromptSubmit hook**: Reports when a user submits a prompt
- **Stop hook**: Reports when a session stops (including rate-limit detection)
- **PostToolUse hook**: Reports tool usage

All events are sent to the UGENT daemon via Unix socket or HTTP fallback.

## Requirements

- UGENT daemon must be running (`ugent start`)
- For Claude Code: Claude Code with plugin support
- For Codex: Codex CLI with plugin support

## Configuration

The plugin automatically detects the UGENT socket at:
- `~/.ugent/run/bridge.sock` (Unix socket)
- Falls back to HTTP if socket is not available

You can override the socket path using the `UGENT_BRIDGE_SOCK` environment variable.

## Repository Structure

```
ugent-monitor/
├── .claude-plugin/
│   └── marketplace.json          # Claude Code marketplace manifest
├── .agents/
│   └── plugins/
│       └── marketplace.json      # Codex marketplace manifest
├── plugins/
│   └── ugent-monitor/            # The actual plugin
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── .codex-plugin/
│       │   └── plugin.json
│       ├── hooks/
│       │   ├── hooks.json
│       │   ├── on_session_start.sh
│       │   ├── on_user_prompt_submit.sh
│       │   ├── on_stop.sh
│       │   ├── on_post_tool_use.sh
│       │   └── lib/
│       │       └── post_event.sh
│       ├── commands/
│       │   └── ugent-resume.md
│       └── README.md
└── README.md                     # This file
```

## Development

To test the plugin locally:

1. Clone this repository
2. Add it as a local marketplace:
   - Claude Code: `/plugin marketplace add /path/to/ugent-monitor`
   - Codex: `codex marketplace add /path/to/ugent-monitor`
3. Install the plugin from the marketplace

## Troubleshooting

### Plugin not showing in Codex

If the plugin doesn't appear in `/plugins`:
1. Check that the marketplace was added: `codex marketplace list`
2. Verify the marketplace.json is valid JSON
3. Restart Codex CLI

### Claude Code version error

If you see "This plugin uses a source type your Claude Code version does not support":
1. Update Claude Code to the latest version
2. The plugin requires Claude Code with marketplace support

### Hooks not firing

1. Verify UGENT daemon is running: `ps aux | grep ugent`
2. Check socket exists: `ls -la ~/.ugent/run/bridge.sock`
3. Test hook manually: `echo '{}' | bash plugins/ugent-monitor/hooks/on_session_start.sh`

## License

MIT
