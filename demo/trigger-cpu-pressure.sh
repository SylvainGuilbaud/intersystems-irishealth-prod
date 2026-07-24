#!/bin/sh
# Alert 6 (Sustained CPU pressure).
# Launches background CPU-burning loops inside the IRIS container. They are tagged
# with DEMOCPULOAD and auto-terminate after 15 minutes; restore-demo.sh kills them.
#
# Expected effect:
#   - iris_cpu_usage climbs
#   - Rule SustainedCPUPressure fires after 10m above 85%
set -eu
cd "$(dirname "$0")/.."

WORKERS="${1:-4}"
echo "[demo] Starting ${WORKERS} CPU-burning worker(s) inside the iris container..."
docker compose exec -d iris sh -c \
  "for i in \$(seq 1 ${WORKERS}); do timeout 900 sh -c 'while :; do :; done' DEMOCPULOAD & done"

echo "[demo] Done. CPU load will run for up to 15 minutes."
echo "       Watch http://localhost:${PROMETHEUS_PORT_HTTP:-9090}/alerts"
