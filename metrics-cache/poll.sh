#!/bin/sh
set -eu

SOURCE_URL="${SOURCE_URL:-http://webgateway-live:80/api/monitor/metrics}"
POLL_INTERVAL="${POLL_INTERVAL:-20}"
REQUEST_TIMEOUT="${REQUEST_TIMEOUT:-8}"
OUTPUT_FILE="${OUTPUT_FILE:-/shared/metrics.prom}"

OUTPUT_DIR="$(dirname "$OUTPUT_FILE")"
TMP_FILE="${OUTPUT_FILE}.tmp"

mkdir -p "$OUTPUT_DIR"

# Ensure a file exists so public metrics endpoints can always serve something.
if [ ! -f "$OUTPUT_FILE" ]; then
  printf '# metrics cache warming up\n' > "$OUTPUT_FILE"
fi

while true; do
  if curl -fsS --max-time "$REQUEST_TIMEOUT" "$SOURCE_URL" -o "$TMP_FILE"; then
    mv "$TMP_FILE" "$OUTPUT_FILE"
    echo "[metrics-cache] cache updated from $SOURCE_URL"
  else
    rm -f "$TMP_FILE"
    echo "[metrics-cache] source unavailable, keeping last successful payload"
  fi

  sleep "$POLL_INTERVAL"
done
