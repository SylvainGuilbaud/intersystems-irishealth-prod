# Runbook: IRIS metrics endpoint / instance unavailable

**Alerts:** `IRISMetricsEndpointDown`, `IRISProductionNotRunning`
**Severity:** critical

## Impact

Monitoring is blind: no IRIS metrics are being collected. Either the InterSystems
IRIS instance is down, the metrics-cache poller has stopped, the internal
`webgateway-live` is unavailable, or both public Web Gateways are down. Clinical
interfaces may also be affected if IRIS itself is down.

## Verification

```bash
docker compose ps
docker compose logs --tail=100 iris
docker compose logs --tail=50 metrics-cache
curl -sS http://localhost:8080/api/monitor/metrics | head
```

In Prometheus, check `up{job=~"iris_metrics_.*"}` and `iris_system_state`.

## Immediate containment

- If IRIS is up but the cache is stale, restart the poller:
  `docker compose restart metrics-cache webgateway-live`
- If IRIS is down, restart it: `docker compose restart iris`

## Root-cause checks

- Review `iris/mgr/messages.log` (inside the container) for startup or licensing errors.
- Confirm the license key is valid (`iris/key/iris.key`).
- Check disk space on the journal/WIJ/database volumes (see the storage runbooks).

## Recovery

Once IRIS and at least one Web Gateway are up and `metrics-cache` reports
`cache updated`, `up` returns to 1 and the alert resolves.

## Escalation

If IRIS repeatedly fails to start or the production will not run, escalate to the
platform owner with `messages.log` and `SystemMonitor.log`.

## Prevention

- Run redundant Web Gateways (this lab already runs nginx + apache).
- Alert on `metrics-cache` staleness and keep the poll interval short.
