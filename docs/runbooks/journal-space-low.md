# Runbook: Journal filesystem space low

**Alert:** `JournalFilesystemSpaceLow`
**Severity:** critical

## Impact

The primary journal directory is low on space. If journaling cannot write, IRIS
suspends updates to protect data integrity — the instance effectively stops
accepting writes. This is a critical, time-sensitive condition.

## Verification

```bash
docker compose exec iris df -h /journal1 /journal2
```

In Prometheus: `iris_jrn_free_space{id="primary"}` (megabytes).

## Immediate containment

- Confirm journal files are being backed up and purged.
- Switch to the alternate journal directory if the current volume is full
  (`CurrentDirectory` / `AlternateDirectory` in `merge.cpf`).
- Free space on the journal volume.

## Root-cause checks

- Journal backup task not running, so old journal files are never purged.
- Abnormally high write volume creating journals faster than they are purged.

## Recovery

Once free space rises above the threshold, the alert resolves. Verify journaling is
active in the Management Portal.

## Escalation

If updates are already suspended, escalate immediately — this affects data
availability.

## Prevention

- Dedicate a volume to journals (this lab mounts `./journal1` and `./journal2`).
- Automate and monitor journal backups; keep `BackupStale` / `JournalBackupStale`
  alerts enabled.
# Runbook: Journal filesystem space low

**Alert:** `JournalFilesystemSpaceLow`
**Severity:** critical

## Impact

The primary journal directory volume is low on space. If journaling cannot write,
IRIS pauses updates to protect data integrity — transactions stall until space is
available. Journaling is also required for backup and recovery.

## Verification

```bash
docker compose exec iris df -h /journal1 /journal2
```

In Prometheus: `iris_jrn_free_space{id="primary"}` (megabytes free).

## Immediate containment

- Switch to the alternate journal directory if the primary volume is full.
- Purge journal files that have already been backed up (never purge unbacked-up
  journals): use the Management Portal or `^JRNSWTCH` / journal purge tooling.

## Root-cause checks

- A backup or journal-copy job has stopped, so old journals are never purged.
- A sudden spike in write activity.

## Recovery

Once free space is above the threshold (2048 MB in this lab), the alert resolves.

## Escalation

If journaling has halted the instance, escalate immediately — this is a
data-availability incident.

## Prevention

- Dedicate a volume to journals with generous headroom.
- Automate journal purge after successful backup and monitor the backup job (see
  `backup-stale.md`).
