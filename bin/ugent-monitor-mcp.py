#!/usr/bin/env python3
"""Minimal stdio MCP server for UGENT Monitor.

This server intentionally has no third-party dependencies. MCP stdio messages
are newline-delimited JSON-RPC, per the 2025-06-18 MCP transport spec. For
compatibility with older LSP-style clients, the reader also accepts
Content-Length framed input and mirrors that framing for responses.
"""

from __future__ import annotations

import json
import os
import pathlib
import sys
import traceback
import urllib.error
import urllib.request
from typing import Any, Dict, Optional, Tuple

SERVER_NAME = "ugent-monitor"
SERVER_VERSION = "0.1.5"
DEFAULT_PROTOCOL_VERSION = "2025-06-18"


def _read_content_length_message(first_line: bytes) -> Optional[Dict[str, Any]]:
    headers: Dict[str, str] = {}
    line = first_line
    while True:
        if line in (b"\r\n", b"\n", b""):
            break
        try:
            name, value = line.decode("ascii").split(":", 1)
            headers[name.strip().lower()] = value.strip()
        except ValueError:
            pass
        line = sys.stdin.buffer.readline()
    length_raw = headers.get("content-length")
    if not length_raw:
        return None
    body = sys.stdin.buffer.read(int(length_raw))
    if not body:
        return None
    return json.loads(body.decode("utf-8"))


def _read_message() -> Tuple[Optional[Dict[str, Any]], str]:
    while True:
        line = sys.stdin.buffer.readline()
        if line == b"":
            return None, "ndjson"
        stripped = line.strip()
        if not stripped:
            continue
        if stripped.lower().startswith(b"content-length:"):
            return _read_content_length_message(line), "content-length"
        return json.loads(line.decode("utf-8")), "ndjson"


def _send(payload: Dict[str, Any], framing: str = "ndjson") -> None:
    body = json.dumps(payload, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    if framing == "content-length":
        sys.stdout.buffer.write(b"Content-Length: " + str(len(body)).encode("ascii") + b"\r\n\r\n" + body)
    else:
        sys.stdout.buffer.write(body + b"\n")
    sys.stdout.buffer.flush()


def _result(message_id: Any, result: Dict[str, Any], framing: str) -> None:
    _send({"jsonrpc": "2.0", "id": message_id, "result": result}, framing)


def _error(message_id: Any, code: int, message: str, framing: str, data: Any = None) -> None:
    err: Dict[str, Any] = {"code": code, "message": message}
    if data is not None:
        err["data"] = data
    _send({"jsonrpc": "2.0", "id": message_id, "error": err}, framing)


def _plan_from_file(path: pathlib.Path) -> Optional[Dict[str, Any]]:
    try:
        if path.exists() and path.is_file():
            data = json.loads(path.read_text(encoding="utf-8"))
            if isinstance(data, dict):
                return data
    except Exception:
        return None
    return None


def _plan_from_http(args: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    base = os.environ.get("UGENT_MONITOR_URL") or os.environ.get("UGENT_URL")
    if not base:
        return None
    url = base.rstrip("/") + "/v1/resume-plan"
    payload = json.dumps(args).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=payload,
        headers={"content-type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=2.0) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            if isinstance(data, dict):
                return data
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError):
        return None
    return None


def _resume_plan(args: Dict[str, Any]) -> Dict[str, Any]:
    plan = _plan_from_http(args)
    if plan:
        return plan

    candidate_paths = []
    env_file = os.environ.get("UGENT_RESUME_PLAN_FILE")
    if env_file:
        candidate_paths.append(pathlib.Path(env_file).expanduser())
    home = pathlib.Path.home()
    candidate_paths.extend([
        home / ".ugent" / "resume-plan.json",
        home / ".ugent" / "monitor" / "resume-plan.json",
    ])
    for path in candidate_paths:
        plan = _plan_from_file(path)
        if plan:
            return plan

    return {
        "ready": True,
        "source": "ugent-monitor-mcp-fallback",
        "session_id": args.get("session_id"),
        "cooldown_until": None,
        "prompt": (
            "Continue the previous UGENT task. Re-read the repo state, recent git "
            "changes, and any visible conversation context before making edits."
        ),
        "notes": [
            "No UGENT resume endpoint or resume-plan file was found.",
            "Set UGENT_MONITOR_URL or UGENT_RESUME_PLAN_FILE for a real plan.",
        ],
    }


TOOLS = [
    {
        "name": "ugent_get_resume_plan",
        "description": "Get the UGENT rate-limit-aware resume plan for the current Codex or Claude Code session.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "session_id": {"type": "string", "description": "Optional session identifier."},
                "cwd": {"type": "string", "description": "Current working directory."},
                "reason": {"type": "string", "description": "Why a resume plan is being requested."},
            },
            "additionalProperties": True,
        },
    }
]


def _handle(request: Dict[str, Any], framing: str) -> None:
    method = request.get("method")
    message_id = request.get("id")
    params = request.get("params") or {}

    if method == "initialize":
        requested = params.get("protocolVersion") if isinstance(params, dict) else None
        _result(
            message_id,
            {
                "protocolVersion": requested or DEFAULT_PROTOCOL_VERSION,
                "capabilities": {"tools": {"listChanged": False}},
                "serverInfo": {"name": SERVER_NAME, "version": SERVER_VERSION},
                "instructions": "Use ugent_get_resume_plan when a UGENT/Codex/Claude session needs rate-limit-aware resume guidance.",
            },
            framing,
        )
        return

    if method in ("notifications/initialized", "initialized"):
        return

    if method == "ping":
        _result(message_id, {}, framing)
        return

    if method == "tools/list":
        _result(message_id, {"tools": TOOLS}, framing)
        return

    if method == "tools/call":
        name = params.get("name") if isinstance(params, dict) else None
        args = params.get("arguments") if isinstance(params, dict) else {}
        if not isinstance(args, dict):
            args = {}
        if name != "ugent_get_resume_plan":
            _error(message_id, -32601, f"Unknown tool: {name}", framing)
            return
        plan = _resume_plan(args)
        _result(message_id, {"content": [{"type": "text", "text": json.dumps(plan, ensure_ascii=False)}]}, framing)
        return

    if message_id is not None:
        _error(message_id, -32601, f"Unknown method: {method}", framing)


def main() -> int:
    current_request: Optional[Dict[str, Any]] = None
    current_framing = "ndjson"
    while True:
        try:
            current_request, current_framing = _read_message()
            if current_request is None:
                return 0
            _handle(current_request, current_framing)
        except Exception as exc:  # Keep the MCP process alive for malformed calls.
            traceback.print_exc(file=sys.stderr)
            try:
                message_id = current_request.get("id") if isinstance(current_request, dict) else None
            except Exception:
                message_id = None
            if message_id is not None:
                _error(message_id, -32603, str(exc), current_framing)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
