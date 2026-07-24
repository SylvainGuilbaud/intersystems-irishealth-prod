#!/usr/bin/env python3
"""Minimal Alertmanager webhook receiver for the monitoring/alerting lab.

Uses only the Python standard library (no external dependencies) so it is safe to
run in a public demo. It exposes:

  POST /alerts   Receives Alertmanager webhook payloads and stores them in memory.
  GET  /         Renders a small HTML page listing the most recent alerts.
  GET  /healthz  Liveness probe.

This receiver intentionally has no persistence and no outbound notifications. In a
real deployment, Alertmanager would route to email, Slack, Teams, PagerDuty, etc.
"""

from __future__ import annotations

import html
import json
from collections import deque
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

MAX_EVENTS = 200
_events: "deque[dict]" = deque(maxlen=MAX_EVENTS)


def _now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")


class Handler(BaseHTTPRequestHandler):
    server_version = "AlertReceiver/1.0"

    def log_message(self, fmt: str, *args) -> None:  # noqa: D401
        # Log to stdout so `docker logs alert-receiver` shows activity.
        print("[alert-receiver] " + (fmt % args), flush=True)

    def _send(self, code: int, body: bytes, content_type: str = "text/plain") -> None:
        self.send_response(code)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:
        if self.path == "/healthz":
            self._send(200, b"ok")
            return
        if self.path.startswith("/alerts"):
            body = json.dumps(list(_events), indent=2).encode()
            self._send(200, body, "application/json")
            return
        self._send(200, self._render_html().encode(), "text/html; charset=utf-8")

    def do_POST(self) -> None:
        if not self.path.startswith("/alerts"):
            self._send(404, b"not found")
            return
        length = int(self.headers.get("Content-Length", "0") or "0")
        raw = self.rfile.read(length) if length else b"{}"
        try:
            payload = json.loads(raw.decode() or "{}")
        except (ValueError, UnicodeDecodeError):
            self._send(400, b"invalid json")
            return

        for alert in payload.get("alerts", []):
            labels = alert.get("labels", {})
            annotations = alert.get("annotations", {})
            _events.appendleft(
                {
                    "received": _now(),
                    "status": alert.get("status", payload.get("status", "unknown")),
                    "alertname": labels.get("alertname", "unknown"),
                    "severity": labels.get("severity", ""),
                    "category": labels.get("category", ""),
                    "instance": labels.get("instance", ""),
                    "summary": annotations.get("summary", ""),
                    "description": annotations.get("description", ""),
                    "runbook_url": annotations.get("runbook_url", ""),
                }
            )
            print(
                f"[alert-receiver] {_events[0]['status'].upper()} "
                f"{_events[0]['alertname']} severity={_events[0]['severity']} "
                f"instance={_events[0]['instance']}",
                flush=True,
            )
        self._send(200, b"received")

    def _render_html(self) -> str:
        rows = []
        for ev in _events:
            status = ev["status"]
            color = {"firing": "#c0392b", "resolved": "#27ae60"}.get(status, "#7f8c8d")
            rows.append(
                "<tr>"
                f"<td>{html.escape(ev['received'])}</td>"
                f"<td style='color:{color};font-weight:600'>{html.escape(status)}</td>"
                f"<td>{html.escape(ev['alertname'])}</td>"
                f"<td>{html.escape(ev['severity'])}</td>"
                f"<td>{html.escape(ev['instance'])}</td>"
                f"<td>{html.escape(ev['summary'])}</td>"
                f"<td>{html.escape(ev['description'])}</td>"
                "</tr>"
            )
        table = "".join(rows) or "<tr><td colspan='7'>No alerts received yet.</td></tr>"
        return (
            "<!doctype html><html><head><meta charset='utf-8'>"
            "<meta http-equiv='refresh' content='10'>"
            "<title>IRIS Alert Receiver</title>"
            "<style>body{font-family:system-ui,sans-serif;margin:2rem;background:#fafafa}"
            "h1{font-size:1.3rem}table{border-collapse:collapse;width:100%}"
            "th,td{border:1px solid #ddd;padding:.4rem .6rem;font-size:.85rem;text-align:left;vertical-align:top}"
            "th{background:#2c3e50;color:#fff}tr:nth-child(even){background:#f0f0f0}</style>"
            "</head><body>"
            f"<h1>IRIS Alert Receiver <small>({len(_events)} recent events, refreshed {_now()})</small></h1>"
            "<table><thead><tr>"
            "<th>Received</th><th>Status</th><th>Alert</th><th>Severity</th>"
            "<th>Instance</th><th>Summary</th><th>Description</th>"
            "</tr></thead><tbody>"
            f"{table}"
            "</tbody></table></body></html>"
        )


def main() -> None:
    server = ThreadingHTTPServer(("0.0.0.0", 8080), Handler)
    print("[alert-receiver] listening on :8080", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        server.shutdown()


if __name__ == "__main__":
    main()
