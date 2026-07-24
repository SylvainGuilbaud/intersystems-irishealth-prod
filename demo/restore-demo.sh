#!/bin/sh
# Restores every demo scenario to a healthy baseline:
#   - restarts the Web Gateways
#   - kills the CPU-burning loops
#   - re-enables the target operation so its queue drains
#   - resumes any suspended messages
#   - refreshes the backup heartbeat globals to "now"
set -eu
cd "$(dirname "$0")/.."

echo "[demo] Starting Web Gateways..."
docker compose start nginx-webgateway apache-webgateway >/dev/null 2>&1 || true

echo "[demo] Killing CPU-burning loops..."
docker compose exec -T iris sh -c "pkill -f DEMOCPULOAD || true" >/dev/null 2>&1 || true

echo "[demo] Re-enabling the target operation and resuming suspended messages..."
printf '%s\n' \
  'do ##class(APP.monitor.Demo).ClearQueue()' \
  'do ##class(APP.monitor.Demo).ResumeMessages()' \
  'set ^APP.Monitor("backup","last")=$ztimestamp' \
  'set ^APP.Monitor("journalbackup","last")=$ztimestamp' \
  'halt' \
  | docker compose exec -T iris iris session IRIS -U APP || true

echo "[demo] Baseline restored. Alerts should resolve within a few evaluation cycles."
