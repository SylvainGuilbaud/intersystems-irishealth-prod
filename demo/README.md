# Demo scenarios

Reproducible, reversible failure scenarios for the monitoring / alerting lab. Each
script disrupts one condition, a metric changes, a Prometheus rule fires, and the
alert is delivered to the local alert receiver. `restore-demo.sh` returns everything
to a healthy baseline.

## Prerequisites

- The stack is running (`./start.sh`).
- Prometheus: <http://localhost:9090> (Alerts tab) · Alertmanager: <http://localhost:9093>
- Alert receiver UI: <http://localhost:8088>
- Grafana: <http://localhost:3000> (see the *IRIS Alerts Overview* dashboard)

## Scenarios

| Script | Alert(s) | Metric that changes |
| --- | --- | --- |
| `trigger-gateway-failure.sh` | `WebGatewayDown` (and `IRISMetricsEndpointDown` if both stopped) | `up{job=~"iris_metrics_.*"}` |
| `trigger-cpu-pressure.sh [workers]` | `SustainedCPUPressure` | `iris_cpu_usage` |
| `trigger-queue-backlog.sh [count]` | `IRISInteroperabilityQueueBacklog` | `iris_interop_queued` |
| `trigger-suspended-message.sh [count]` | `IRISSuspendedMessages` | `iris_interop_messages_suspended` |
| `trigger-backup-stale.sh` | `BackupStale`, `JournalBackupStale` | `app_backup_age_seconds` |
| `restore-demo.sh` | — resolves all of the above | — |

Each script prints the URLs to watch. Rules use a `for:` duration, so allow the
configured time (1–10 minutes) before an alert transitions to *firing*.

## Lifecycle to observe

1. **What is disrupted** — the script output states the target.
2. **Which metric changes** — check Prometheus *Graph* for the metric above.
3. **Which rule fires** — Prometheus *Alerts* tab (pending → firing).
4. **How the alert appears** — Alertmanager and the alert-receiver UI.
5. **Corrective action** — see the linked runbook in `docs/runbooks/`.
6. **Resolution** — run `restore-demo.sh`; Prometheus marks the alert resolved and
   Alertmanager sends a `resolved` notification.

## Notes and gotchas

- `iris_interop_queued` only reports business hosts that have a **queue-count alert**
  configured. `trigger-queue-backlog.sh` attempts to enable it on the target host; if
  the metric stays empty, enable *Alert Queue Count* on the host in the Management
  Portal (Interoperability → Configure → Production).
- The interoperability scenarios require the production `APPPKG.FoundationProduction`
  to be running.
- Thresholds in `prometheus/rules/*.yml` and the Docker topology are **demonstration
  defaults**, not universal production recommendations.
