# UGENT Monitor Plugin

UGENT Monitor provides a Claude Code and Codex plugin that reports session lifecycle events to UGENT and exposes a small MCP resume-planning tool.

## Claude Code install

This repository intentionally uses the same root-level marketplace layout as `snarktank/ralph`:

- `.claude-plugin/marketplace.json` lists the plugin with `"source": "./"`.
- `.claude-plugin/plugin.json` is the plugin manifest.
- `skills/`, `commands/`, `hooks/`, `.mcp.json`, and `bin/` are at the repository root.

Install:

```text
/plugin marketplace remove ugent-monitor
/plugin marketplace add unizhu/ugent-monitor
/plugin marketplace update ugent-monitor
/plugin install ugent-monitor@ugent-monitor
/reload-plugins
```

If Claude still reports an unsupported source type, check the live marketplace file:

```bash
curl -fsSL https://raw.githubusercontent.com/unizhu/ugent-monitor/main/.claude-plugin/marketplace.json | jq '.plugins[0].source'
```

It must print:

```json
"./"
```

If it prints `git-subdir`, the GitHub repo was not updated with this package yet.

## Codex install

Codex uses the nested plugin under `plugins/ugent-monitor` and the marketplace at `.agents/plugins/marketplace.json`.

```bash
codex plugin marketplace remove ugent-monitor
rm -rf ~/.codex/.tmp/marketplaces/ugent-monitor
codex plugin marketplace add unizhu/ugent-monitor
codex plugin marketplace upgrade ugent-monitor
codex
```

Then open `/plugins`, install `ugent-monitor`, enable it, and trust the hooks.

## Components

- Skill/command: `ugent-resume`
- Hooks: `SessionStart`, `UserPromptSubmit`, `PostToolUse`, `Stop`
- MCP tool: `ugent_get_resume_plan`

## Environment variables

The hook scripts are no-ops unless UGENT endpoint variables are configured.

- `UGENT_MONITOR_URL`
- `UGENT_MONITOR_TOKEN`
