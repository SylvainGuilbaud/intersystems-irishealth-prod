# intersystems-irishealth-prod

Langue : Français | [English](README.md)

Ce depôt fournit un environnement InterSystems IRIS for Health basé sur Docker pour une production d'interopérabilité, avec deux Web Gateways indépendants (Apache et NGINX) et une pile de supervision Prometheus/Grafana.

## Ce que la stack exécute

- Un conteneur IRIS for Health construit depuis [iris/Dockerfile](iris/Dockerfile).
- Un Web Gateway Apache configuré par [webgateway/CSP.conf](webgateway/CSP.conf) et [webgateway/CSP.ini](webgateway/CSP.ini).
- Un Web Gateway NGINX indépendant configuré par [nginx/CSP.conf](nginx/CSP.conf) et [nginx/CSP.ini](nginx/CSP.ini).
- Un Web Gateway Apache interne dédié (`webgateway-live`) utilisé uniquement comme source métriques live.
- Un sidecar `metrics-cache` qui conserve la dernière payload métriques valide pour un service public stable.
- Les sources ObjectScript sous [iris/src](iris/src).

Pendant le build image, [iris/iris.script](iris/iris.script) est exécuté et fait les opérations suivantes :

1. Bascule dans le namespace `DGLAB`.
2. Importe les classes depuis `/home/irisowner/dev/src`.
3. Crée un paramètre par défaut système `TECHNIDATA` avec la valeur `DGLAB-V2`.
4. Positionne `Deployable=1` sur ce paramètre (`$lb(SettingValue, Description, Deployable)`).

## Services Docker Compose

Définis dans [docker-compose.yml](docker-compose.yml) :

### iris

- Contexte de build : [iris](iris)
- Argument image de base : `containers.intersystems.com/intersystems/irishealth:latest-em`
- Nom du conteneur : `irishealth`
- Hostname : `irishealth`
- Ports : `${IRIS_PORT}:1972`
- Volumes persistants et montages hôte :
  - `iris-data:/iris-data`
  - `./journal1:/journal1`
  - `./journal2:/journal2`
  - `./wij:/wij`
  - [iris/key/iris.key](iris/key/iris.key.to_replace_with_your_IRIS_key) monté en `/tmp/iris.key` (lecture seule)
  - [iris/python/iris_python_demo](iris/python/iris_python_demo) monté dans le répertoire Python manager d'IRIS
  - [merge.cpf](merge.cpf) fusionné au démarrage via `ISC_CPF_MERGE_FILE`

### apache-webgateway

- Image : `containers.intersystems.com/intersystems/webgateway:latest-em`
- Dépend de `iris`
- Ports :
  - `${WEBGATEWAY_PORT_HTTP}:80`
  - `${WEBGATEWAY_PORT_HTTPS}:443`
- Fichiers de configuration montés depuis [webgateway](webgateway)

### nginx-webgateway

- Image : `containers.intersystems.com/intersystems/webgateway-nginx:latest-preview`
- Dépend de `iris`
- Port :
  - `${NGINX_PORT_HTTP}:80`
- Fichiers de configuration montés depuis [nginx](nginx)
- Indépendant du gateway Apache pour le trafic utilisateur.

### webgateway-live

- Image : `containers.intersystems.com/intersystems/webgateway:latest-em`
- Dépend de `iris`
- Aucun port hôte publié
- Utilise [webgateway/CSP-live.conf](webgateway/CSP-live.conf)
- Réservé au polling interne par `metrics-cache`

### Pourquoi `webgateway-live` existe

`webgateway-live` est un conteneur source métriques interne uniquement.

Il n'est pas destiné au trafic utilisateur et n'est exposé sur aucun port hôte.
Son seul rôle est de fournir un endpoint live `/api/monitor/metrics` à `metrics-cache`.

Flux de fonctionnement :

1. `metrics-cache` interroge `webgateway-live` toutes les 20 secondes.
2. A chaque réponse réussie, `metrics-cache` écrit la payload dans un fichier partagé.
3. Les endpoints métriques publics Apache (`apache-webgateway`) et NGINX (`nginx-webgateway`) servent ce fichier partagé en cache.

Cette approche garde Apache et NGINX indépendants pour l'accès utilisateur tout en rendant les endpoints métriques publics beaucoup plus stables lors des erreurs transitoires CSP/Web Gateway.

### metrics-cache

- Contexte de build local : [metrics-cache](metrics-cache)
- Dépend de `webgateway-live`
- Aucun port hôte publié
- Interroge `http://webgateway-live:80/api/monitor/metrics` toutes les 20 secondes
- Persiste la dernière payload réussie dans un fichier partagé servi par les deux gateways publics

### prometheus

- Image : `prom/prometheus:v2.54.1`
- Dépend de `nginx-webgateway`, `apache-webgateway` et `metrics-cache`
- Port : `${PROMETHEUS_PORT_HTTP}:9090`
- Fichier de configuration : [prometheus/prometheus.yml](prometheus/prometheus.yml)
- Scrape les métriques depuis :
  - `http://nginx-webgateway:80/api/monitor/metrics`
  - `http://apache-webgateway:80/api/monitor/metrics`

### grafana

- Image : `grafana/grafana:11.2.0`
- Dépend de `prometheus`
- Port : `${GRAFANA_PORT_HTTP}:3000`
- Provisioning :
  - Datasource : [grafana/provisioning/datasources/prometheus.yml](grafana/provisioning/datasources/prometheus.yml)
  - Provider dashboards : [grafana/provisioning/dashboards/dashboards.yml](grafana/provisioning/dashboards/dashboards.yml)
  - Dashboard JSON : [grafana/dashboards/iris-overview.json](grafana/dashboards/iris-overview.json)

## Prérequis

1. Docker et Docker Compose installés.
2. Un fichier `.env` local avec au minimum :
   - `IRIS_PORT`
   - `NGINX_PORT_HTTP`
   - `WEBGATEWAY_PORT_HTTP`
   - `WEBGATEWAY_PORT_HTTPS`
   - `PROMETHEUS_PORT_HTTP`
   - `GRAFANA_PORT_HTTP`
   - `GRAFANA_ADMIN_USER`
   - `GRAFANA_ADMIN_PASSWORD`
3. Votre clé IRIS copiée dans [iris/key/iris.key](iris/key/iris.key.to_replace_with_your_IRIS_key).
4. Les répertoires locaux [journal1](journal1), [journal2](journal2) et [wij](wij) présents à la racine du dépôt pour les montages journal/WIJ.

## Démarrer et arrêter

Démarrage (rebuild et lancement) :

```bash
./start.sh
```

Le script :

- Arrête les services existants.
- Corrige le propriétaire/permissions sur le volume `iris-data`.
- Exécute `docker compose up -d --build --remove-orphans`.

Arrêt :

```bash
./stop.sh
```

## Métriques et supervision

- Endpoints métriques publics :
  - Gateway Apache : `http://localhost:${WEBGATEWAY_PORT_HTTP}/api/monitor/metrics`
  - Gateway NGINX : `http://localhost:${NGINX_PORT_HTTP}/api/monitor/metrics`
- UI Prometheus : `http://localhost:${PROMETHEUS_PORT_HTTP}`
- Un intervalle de scrape de 20s est configuré dans [prometheus/prometheus.yml](prometheus/prometheus.yml).
- Les endpoints publics `/api/monitor/metrics` sont servis depuis un fichier cache partagé écrit par `metrics-cache`. Cela évite les `503 Service Unavailable` transitoires du chemin CSP live tout en conservant l'indépendance Apache/NGINX.
- Le chemin source live reste interne via `webgateway-live` et n'est pas exposé sur l'hôte.
- UI Grafana : `http://localhost:${GRAFANA_PORT_HTTP}`
- Les identifiants par défaut viennent du `.env` (`GRAFANA_ADMIN_USER` / `GRAFANA_ADMIN_PASSWORD`).
- Dashboard provisionné : `IRIS / IRIS Overview`.

## Outils d'exploitation

- [terminal.sh](terminal.sh) : ouvre une session terminal IRIS dans le conteneur choisi.

## Organisation des sources

- [iris/src/DGLABPKG/FoundationProduction.cls](iris/src/DGLABPKG/FoundationProduction.cls) : définition de la production.
- [iris/src/DGLAB/router/HL7.cls](iris/src/DGLAB/router/HL7.cls) : règles de routage HL7.
- [iris/src/DGLAB/transfo](iris/src/DGLAB/transfo) : transformations de messages.
