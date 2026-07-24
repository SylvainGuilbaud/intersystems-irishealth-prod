# Runbook: Web Gateway unavailable

**Alert:** `WebGatewayDown`
**Severity:** warning

## Impact

One public Web Gateway (nginx or apache) is not responding. User-facing traffic may
degrade, and Prometheus can no longer scrape metrics through that gateway. If both
gateways are down, `IRISMetricsEndpointDown` escalates to critical.

## Verification

```bash
docker compose ps nginx-webgateway apache-webgateway
docker compose logs --tail=100 nginx-webgateway
curl -sS -o /dev/null -w '%{http_code}\n' http://localhost:8080/api/monitor/metrics
```

In Prometheus: `up{job=~"iris_metrics_.*"}` — identify which `gateway` label is 0.

## Immediate containment

Restart the affected gateway:

```bash
docker compose restart nginx-webgateway   # or apache-webgateway
```

## Root-cause checks

- Gateway configuration (`nginx/CSP.conf`, `webgateway/CSP.conf`).
- Connectivity from the gateway to IRIS (superserver port 1972).
- The `metrics-cache-data` volume is mounted read-only and populated.

## Recovery

When the gateway responds again, `up` returns to 1 and the alert resolves.

## Escalation

If a gateway crashes repeatedly, capture its logs and escalate to the web-tier owner.

## Prevention

- Keep at least two gateways in front of IRIS.
- Health-check gateways from the load balancer.
