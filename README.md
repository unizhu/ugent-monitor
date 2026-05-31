# UGENT Monitor Plugin

UGENT Monitor reports Claude Code/Codex lifecycle events to a local UGENT endpoint and provides a `ugent-resume` skill plus a minimal dependency-free MCP server.

## What this version fixes

- Claude Code marketplace source is Ralph-style `"./"`, avoiding `git-subdir` and object-source compatibility issues.
- Codex MCP server now uses newline-delimited MCP stdio JSON-RPC, not LSP `Content-Length` framing.
- Codex MCP launch uses a Python inline bootstrapper that locates the installed plugin cache, working around current Codex relative-path behavior in plugin `.mcp.json` files.
- All manifests are versioned `0.1.6`.

## Claude Code install

```text
/plugin marketplace remove ugent-monitor
/plugin marketplace add unizhu/ugent-monitor
/plugin marketplace update ugent-monitor
/plugin install ugent-monitor@ugent-monitor
/reload-plugins
```

Validate locally before pushing:

```bash
claude plugin validate .
claude plugin validate . --strict
claude --plugin-dir .
```

Claude root layout:

```text
.claude-plugin/marketplace.json
.claude-plugin/plugin.json
skills/ugent-resume/SKILL.md
commands/ugent-resume.md
hooks/hooks.json
.mcp.json
bin/ugent-monitor-mcp.py
```

## Codex install

```bash
codex plugin marketplace remove ugent-monitor
rm -rf ~/.codex/.tmp/marketplaces/ugent-monitor
rm -rf ~/.codex/plugins/cache/ugent-monitor
codex plugin marketplace add unizhu/ugent-monitor
codex plugin marketplace upgrade ugent-monitor
codex
```

In Codex, install/enable the plugin in `/plugins`. Then inspect MCP:

```text
/mcp
```

Expected server/tool after the plugin is enabled:

```text
ugent-monitor
mcp__ugent-monitor__ugent_get_resume_plan
```

Codex nested layout:

```text
.agents/plugins/marketplace.json
plugins/ugent-monitor/.codex-plugin/plugin.json
plugins/ugent-monitor/.mcp.json
plugins/ugent-monitor/skills/ugent-resume/SKILL.md
plugins/ugent-monitor/hooks/hooks.json
plugins/ugent-monitor/bin/ugent-monitor-mcp.py
```

## Environment variables

Optional runtime integrations:

```bash
export UGENT_MONITOR_URL="http://127.0.0.1:8786"
export UGENT_RESUME_PLAN_FILE="$HOME/.ugent/resume-plan.json"
```

The MCP tool falls back to a safe static resume plan when neither variable is set.
