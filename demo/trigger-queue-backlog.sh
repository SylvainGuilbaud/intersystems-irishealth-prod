#!/bin/sh
# Alert 8 (Interoperability queue backlog).
# Disables the "to EMR - FILE" operation and injects queued messages via the
# EnsLib.Testing.Service so the queue depth grows.
#
# Expected effect:
#   - iris_interop_queued for the host grows (requires a queue-count alert on the
#     host; the helper attempts to enable it automatically)
#   - Rule IRISInteroperabilityQueueBacklog fires after 5m
set -eu
cd "$(dirname "$0")/.."

COUNT="${1:-150}"
echo "[demo] Injecting ${COUNT} queued messages (production must be running)..."
printf 'set sc=##class(APP.monitor.Demo).QueueBacklog(%s) write:$$$ISERR(sc) $system.Status.GetErrorText(sc)\nhalt\n' "${COUNT}" \
  | docker compose exec -T iris iris session IRIS -U APP

echo "[demo] Done. Watch the queue in the Management Portal and Prometheus:"
echo "       http://localhost:${PROMETHEUS_PORT_HTTP:-9090}/alerts"
