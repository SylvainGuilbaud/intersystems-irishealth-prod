# Runbook: Interoperability queue backlog

**Alerts:** `IRISInteroperabilityQueueBacklog`, `IRISInteroperabilityHostNotOK`
**Severity:** warning

## Impact

A business host's queue is deep and still growing. Messages are being received faster
than they are processed, increasing end-to-end latency. Left unchecked, downstream
systems fall behind and storage grows.

## Verification

In Prometheus:

```promql
iris_interop_queued{gateway="nginx"}
deriv(iris_interop_queued{gateway="nginx"}[5m])
iris_interop_hosts{gateway="nginx", status=~"Error|Retry"}
```

In the Management Portal: Interoperability → Monitor → Queues and Production Monitor.

> **Note:** `iris_interop_queued` only reports hosts with a *queue-count alert*
> configured. If a growing queue does not appear, enable *Alert Queue Count* on the
> host.

## Immediate containment

- Identify the slow or stopped host (`$labels.host`).
- If a downstream operation is disabled or in Error/Retry, correct the connectivity
  issue and re-enable it so the queue drains.
- Consider increasing the host `PoolSize` if the backlog is throughput-related.

## Root-cause checks

- Downstream endpoint unavailable (network, credentials, remote outage).
- A poison message repeatedly failing and blocking the queue.
- Undersized pool for the current message rate.

## Recovery

When the queue drains and `deriv(...)` is no longer positive, the alert resolves.

## Escalation

Escalate to the interface owner if the downstream system is the bottleneck.

## Prevention

- Alert on queue **depth + growth rate + message age**, not a fixed size — a queue of
  500 may be normal for one interface and catastrophic for another.
- Right-size pools and set per-host queue-count alerts.
