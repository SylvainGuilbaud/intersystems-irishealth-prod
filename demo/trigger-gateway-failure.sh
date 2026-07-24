#!/bin/sh
# Alert 2 (Web Gateway unavailable) and, if both are stopped, Alert 1.
# Stops the public NGINX Web Gateway so Prometheus can no longer scrape it.
#
# Expected effect:
#   - up{job="iris_metrics_nginx"} -> 0
#   - Rule WebGatewayDown fires after ~1m (severity: warning)
#   - Restore with ./demo/restore-demo.sh
set -eu
cd "$(dirname "$0")/.."

echo "[demo] Stopping the nginx-webgateway container..."
docker compose stop nginx-webgateway

echo "[demo] Done. Watch Prometheus (Alerts tab) and the alert receiver:"
echo "       http://localhost:${PROMETHEUS_PORT_HTTP:-9090}/alerts"
echo "       http://localhost:${ALERT_RECEIVER_PORT_HTTP:-8088}/"
echo "[demo] Tip: stop apache-webgateway too to trigger IRISMetricsEndpointDown (critical)."
