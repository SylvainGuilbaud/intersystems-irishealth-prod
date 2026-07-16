# intersystems-irishealth-prod

This repository provides a Docker-based InterSystems IRIS for Health environment for an interoperability production, with a Web Gateway front end.

## What This Stack Runs

- An IRIS for Health container built from [iris/Dockerfile](iris/Dockerfile).
- A Web Gateway container configured by [webgateway/CSP.conf](webgateway/CSP.conf) and [webgateway/CSP.ini](webgateway/CSP.ini).
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
  - `/journal1:/journal1`
  - `/journal2:/journal2`
  - `/wij:/wij`
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

## Prerequisites

1. Docker and Docker Compose installed.
2. A local `.env` file with at least:
   - `IRIS_PORT`
   - `WEBGATEWAY_PORT_HTTP`
   - `WEBGATEWAY_PORT_HTTPS`
3. Your IRIS key file copied to [iris/key/iris.key](iris/key/iris.key.to_replace_with_your_IRIS_key).
4. Existing host directories `/journal1`, `/journal2`, and `/wij` (or update [docker-compose.yml](docker-compose.yml) to paths available on your machine).

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

## Operational Helpers

- [terminal.sh](terminal.sh): opens an IRIS terminal session in a selected container.

## Source Layout

- [iris/src/DGLABPKG/FoundationProduction.cls](iris/src/DGLABPKG/FoundationProduction.cls): production definition.
- [iris/src/DGLAB/router/HL7.cls](iris/src/DGLAB/router/HL7.cls): HL7 routing rules.
- [iris/src/DGLAB/transfo](iris/src/DGLAB/transfo): message transforms.

