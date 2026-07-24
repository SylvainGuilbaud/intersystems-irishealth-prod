# Runbook: Backup / journal-backup stale

**Alerts:** `BackupStale`, `JournalBackupStale`
**Severity:** warning

## Impact

No recent successful backup (or journal backup) has been recorded. Recovery Point
Objective is at risk: a failure now could lose more data than the business tolerates.

## Verification

In Prometheus: `app_backup_age_seconds`, `app_journal_backup_age_seconds` (seconds
since the last recorded backup; the threshold is 90000s ≈ 25h).

The heartbeat is stored in the `^APP.Monitor` global and updated by your backup
job. Confirm the backup process wrote a fresh timestamp on its last run.

## Immediate containment

- Run a backup manually and confirm it completes successfully.
- Ensure the backup job records its completion into the heartbeat global:
  `set ^APP.Monitor("backup","last") = $ztimestamp` (UTC).

## Root-cause checks

- Scheduled backup task disabled or failing.
- Backup target (storage/share) unavailable.
- Heartbeat not being written even though the backup ran.

## Recovery

Once a fresh backup timestamp is recorded, `app_backup_age_seconds` drops below the
threshold and the alert resolves. In the lab, `restore-demo.sh` refreshes the
heartbeat to "now".

## Escalation

Escalate to the operations owner if backups cannot complete.

## Prevention

- Treat the backup heartbeat as a first-class monitored signal.
- Alert on staleness (absence of success), not just on failure events.
