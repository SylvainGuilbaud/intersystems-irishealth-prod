# Runbook: Database volume space low

**Alert:** `DatabaseSpaceLow` (also `ContainerFilesystemSpaceLow`)
**Severity:** warning

## Impact

A database's storage volume is nearly full. If it fills completely, IRIS cannot
expand the database and writes will fail, potentially halting the production.

## Verification

```bash
docker compose exec iris df -h
```

In Prometheus: `iris_disk_percent_full` and `iris_db_free_space{id="<database>"}`
(the latter updates once per day).

## Immediate containment

- Free space on the host volume, or expand the Docker volume.
- Purge obsolete data (e.g. old interoperability messages) if appropriate.

## Root-cause checks

- Unexpected data growth or a runaway process writing to a database.
- Message retention / purge tasks not running (see the interoperability purge task).

## Recovery

After space is reclaimed or the volume is expanded, `iris_disk_percent_full` drops
below the threshold and the alert resolves.

## Escalation

Escalate to storage/infrastructure if the underlying host volume cannot be expanded.

## Prevention

- Capacity-plan database growth and set `iris_db_free_space` thresholds accordingly.
- Schedule and monitor message-purge tasks.
