#!/bin/sh
# Alert 10 (Backup / journal-backup stale).
# Sets the backup heartbeat globals to a timestamp three days in the past so the
# custom app_backup_age_seconds / app_journal_backup_age_seconds metrics exceed the
# staleness threshold.
#
# Expected effect:
#   - Rules BackupStale / JournalBackupStale fire after 5m
set -eu
cd "$(dirname "$0")/.."

echo "[demo] Ageing the backup heartbeat globals by 3 days..."
printf '%s\n' \
  'set x=$ztimestamp,$piece(x,",",1)=$piece(x,",",1)-3' \
  'set ^APP.Monitor("backup","last")=x' \
  'set ^APP.Monitor("journalbackup","last")=x' \
  'halt' \
  | docker compose exec -T iris iris session IRIS -U APP

echo "[demo] Done. Watch http://localhost:${PROMETHEUS_PORT_HTTP:-9090}/alerts"
