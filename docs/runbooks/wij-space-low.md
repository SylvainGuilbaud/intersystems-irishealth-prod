# Runbook: WIJ filesystem space low

**Alert:** `WIJFilesystemSpaceLow`
**Severity:** critical

## Impact

The write image journal (WIJ) directory is low on space. The WIJ is essential for
crash recovery; if it cannot be written, IRIS will block writes to protect data
integrity.

## Verification

```bash
docker compose exec iris df -h /wij
```

In Prometheus: `iris_jrn_free_space{id="WIJ"}` (megabytes).

## Immediate containment

- Free space on the WIJ volume.
- Verify the WIJ location (`wijdir` in `merge.cpf`) points to a volume with adequate
  headroom.

## Root-cause checks

- WIJ sized larger than expected due to large write bursts.
- The WIJ volume shared with other data that has grown.

## Recovery

When free space rises above the threshold the alert resolves.

## Escalation

If writes are already blocked, escalate immediately.

## Prevention

- Place the WIJ on a dedicated, adequately sized volume (this lab mounts `./wij`).
- Capacity-plan for peak write bursts.
