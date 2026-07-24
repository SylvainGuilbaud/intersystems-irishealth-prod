#!/bin/sh
# Alert 9 (Suspended interoperability messages).
# Marks the most recent message headers as Suspended.
#
# Expected effect:
#   - iris_interop_messages_suspended > 0
#   - Rule IRISSuspendedMessages fires after 1m
# Note: there must be at least one message in the production. Run
#       ./demo/trigger-queue-backlog.sh first if the message store is empty.
set -eu
cd "$(dirname "$0")/.."

COUNT="${1:-2}"
echo "[demo] Suspending ${COUNT} recent message header(s)..."
printf 'set sc=##class(APP.monitor.Demo).SuspendMessages(%s) write:$$$ISERR(sc) $system.Status.GetErrorText(sc)\nhalt\n' "${COUNT}" \
  | docker compose exec -T iris iris session IRIS -U APP

echo "[demo] Done. Watch http://localhost:${PROMETHEUS_PORT_HTTP:-9090}/alerts"
