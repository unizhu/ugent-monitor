---
name: ugent-resume
description: Ask UGENT whether the rate-limit cooldown is over and what prompt to inject next.
---

You are continuing a previously rate-limited Claude Code or Codex session.
Read the current state from the local UGENT bridge by calling the
`ugent_get_resume_plan` MCP tool (if installed) and follow the prompt it returns.

If the MCP tool is not available, the user wants you to continue the previous
work where you left off. Re-read recent files, the git log, and the conversation
history above, then proceed.
