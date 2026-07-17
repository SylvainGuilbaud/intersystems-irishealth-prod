# intersystems-irishealth-prod

This repository provides a Docker-based InterSystems IRIS for Health environment for an interoperability production, with independent Apache and NGINX Web Gateway front ends plus a Prometheus/Grafana monitoring stack.

## What This Stack Runs

- An IRIS for Health container built from [iris/Dockerfile](iris/Dockerfile).
- An Apache Web Gateway container configured by [webgateway/CSP.conf](webgateway/CSP.conf) and [webgateway/CSP.ini](webgateway/CSP.ini).
- An independent NGINX Web Gateway container configured by [nginx/CSP.conf](nginx/CSP.conf) and [nginx/CSP.ini](nginx/CSP.ini).
- A dedicated internal Apache Web Gateway used only as a live metrics source.
- A `metrics-cache` sidecar that stores the last successful metrics payload for stable public serving.
- The ObjectScript sources under [iris/src](iris/src).

During image build, [iris/iris.script](iris/iris.script) is executed and does the following:

1. Switches to namespace `DGLAB`.
2. Imports classes from `/home/irisowner/dev/src`.
3. Creates a system-wide default setting for `TECHNIDATA` with value `DGLAB-V2`.
4. Sets `Deployable=1` for that default setting (`$lb(SettingValue, Description, Deployable)`).

## Docker Compose Services

Defined in [docker-compose.yml](docker-compose.yml):

### iris

- Build context: [iris](iris)
- Base image arg: `containers.intersystems.com/intersystems/irishealth:latest-em`
- Container name: `irishealth`
- Hostname: `irishealth`
- Ports: `${IRIS_PORT}:1972`
- Persistent and host mounts:
  - `iris-data:/iris-data`
  - `./journal1:/journal1`
  - `./journal2:/journal2`
  - `./wij:/wij`
  - [iris/key/iris.key](iris/key/iris.key.to_replace_with_your_IRIS_key) as `/tmp/iris.key` (read-only)
  - [iris/python/iris_python_demo](iris/python/iris_python_demo) mounted in IRIS mgr python path
  - [merge.cpf](merge.cpf) merged at startup via `ISC_CPF_MERGE_FILE`

### webgateway

- Image: `containers.intersystems.com/intersystems/webgateway:latest-em`
- Depends on `iris`
- Ports:
  - `${WEBGATEWAY_PORT_HTTP}:80`
  - `${WEBGATEWAY_PORT_HTTPS}:443`
- Config files mounted from [webgateway](webgateway)

### nginx

- Image: `containers.intersystems.com/intersystems/webgateway-nginx:latest-preview`
- Depends on `iris`
- Port:
  - `${NGINX_PORT_HTTP}:80`
- Config files mounted from [nginx](nginx)
- Independent from the Apache gateway for user traffic.

### webgateway-live

- Image: `containers.intersystems.com/intersystems/webgateway:latest-em`
- Depends on `iris`
- No host port published.
- Uses [webgateway/CSP-live.conf](webgateway/CSP-live.conf).
- Reserved for internal polling by `metrics-cache`.

### metrics-cache

- Local build context: [metrics-cache](metrics-cache)
- Depends on `webgateway-live`
- No host port published.
- Polls `http://webgateway-live:80/api/monitor/metrics` every 20 seconds.
- Persists the last successful payload to a shared file served by both public gateways.

### prometheus

- Image: `prom/prometheus:v2.54.1`
- Depends on `nginx`, `webgateway`, and `metrics-cache`
- Port: `${PROMETHEUS_PORT_HTTP}:9090`
- Config file: [prometheus/prometheus.yml](prometheus/prometheus.yml)
- Scrapes metrics from:
  - `http://nginx:80/api/monitor/metrics`
  - `http://webgateway:80/api/monitor/metrics`

### grafana

- Image: `grafana/grafana:11.2.0`
- Depends on `prometheus`
- Port: `${GRAFANA_PORT_HTTP}:3000`
- Provisioning:
  - Datasource: [grafana/provisioning/datasources/prometheus.yml](grafana/provisioning/datasources/prometheus.yml)
  - Dashboards provider: [grafana/provisioning/dashboards/dashboards.yml](grafana/provisioning/dashboards/dashboards.yml)
  - Dashboard JSON: [grafana/dashboards/iris-overview.json](grafana/dashboards/iris-overview.json)

## Prerequisites

1. Docker and Docker Compose installed.
2. A local `.env` file with at least:
  - `IRIS_PORT`
  - `NGINX_PORT_HTTP`
  - `WEBGATEWAY_PORT_HTTP`
  - `WEBGATEWAY_PORT_HTTPS`
  - `PROMETHEUS_PORT_HTTP`
  - `GRAFANA_PORT_HTTP`
  - `GRAFANA_ADMIN_USER`
  - `GRAFANA_ADMIN_PASSWORD`
3. Your IRIS key file copied to [iris/key/iris.key](iris/key/iris.key.to_replace_with_your_IRIS_key).
4. Existing local directories [journal1](journal1), [journal2](journal2), and [wij](wij) in the repository root for journal and WIJ mounts.

## Start and Stop

Start (rebuild and launch):

```bash
./start.sh
```

The script:

- Stops existing services.
- Fixes owner/permissions on the `iris-data` volume.
- Runs `docker compose up -d --build --remove-orphans`.

Stop:

```bash
./stop.sh
```

## Metrics and Monitoring

- Public metrics endpoints:
  - Apache Web Gateway: `http://localhost:${WEBGATEWAY_PORT_HTTP}/api/monitor/metrics`
  - NGINX Web Gateway: `http://localhost:${NGINX_PORT_HTTP}/api/monitor/metrics`
- Prometheus UI: `http://localhost:${PROMETHEUS_PORT_HTTP}`
- A scrape interval of 20s is configured in [prometheus/prometheus.yml](prometheus/prometheus.yml).
- Public `/api/monitor/metrics` endpoints are served from a shared cached file written by `metrics-cache`. This avoids transient `503 Service Unavailable` responses from the live CSP path while keeping Apache and NGINX independent.
- The live source path remains internal via `webgateway-live` and is not exposed on the host.
- Grafana UI: `http://localhost:${GRAFANA_PORT_HTTP}`
- Default login is provided by `.env` (`GRAFANA_ADMIN_USER` / `GRAFANA_ADMIN_PASSWORD`).
- Provisioned dashboard: `IRIS / IRIS Overview`.

## Operational Helpers

- [terminal.sh](terminal.sh): opens an IRIS terminal session in a selected container.

## Source Layout

- [iris/src/DGLABPKG/FoundationProduction.cls](iris/src/DGLABPKG/FoundationProduction.cls): production definition.
- [iris/src/DGLAB/router/HL7.cls](iris/src/DGLAB/router/HL7.cls): HL7 routing rules.
- [iris/src/DGLAB/transfo](iris/src/DGLAB/transfo): message transforms.

