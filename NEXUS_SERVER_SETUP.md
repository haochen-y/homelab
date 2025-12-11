# Nexus + Postgres Setup Guide

This document summarizes the exact steps used to stand up Sonatype Nexus 3
backed by Postgres via the local `docker-compose.yml` and `.env`. It mirrors the
sequence recommended in the official Nexus/Datastore documentation (Sonatype
"Datastore" guide) but is tailored to this homelab.

## Prerequisites
- Docker Engine and Docker Compose v2
- The files in this repo: `.env`, `docker-compose.yml`
- Port `4926` available on the host (proxies to Nexus port 8081)
- Port `4925` available on the host (proxies to Postgres port 5432)

> The `.env` file already contains sensible defaults for local testing. Adjust
> them before exposing the stack externally.

## 1. Load environment variables in your shell
Many Docker commands need the values defined in `.env`. Rather than prefixing
commands with `ENV_VAR=value`, temporarily enable automatic export (`set -a`),
source the file, then disable it (`set +a`).

```bash
set -a
source .env
set +a
```

You can confirm that the variables are in the environment with `env | grep
POSTGRES`.

## 2. Start the stack
The compose file defines two services: `postgres` (tagged 17) and
`sonatype/nexus3`. Bring them up in detached mode:

```bash
docker compose up -d
```

Monitor logs until Nexus finishes booting (it can take a few minutes the first
run):

```bash
docker compose logs -f nexus
```

Stop the stack with `docker compose down`. Add `--volumes` if you truly want to
wipe data.

## 3. Postgres pg_trgm extension
Nexus search uses PostgreSQL trigram matching. The Sonatype datastore docs state
that you must enable `pg_trgm` in the Nexus database.

1. Open a psql shell *inside* the Postgres container:

   ```bash
   docker exec -it nexus-postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"
   ```

   With the defaults in `.env` that equals:

   ```bash
   docker exec -it nexus-postgres psql -U nexus -d nexus
   ```

2. Install the extension, list enabled extensions, and quit:

   ```sql
   CREATE EXTENSION IF NOT EXISTS pg_trgm;
   \dx
   \q
   ```

   If you prefer a one-liner without an interactive shell:

   ```bash
   docker exec -it nexus-postgres \
     psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
     -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
   ```

The extension is persistent because the Postgres data directory is mapped to the
`pgdata` volume (`/var/lib/postgresql/data`).

## 4. Verify Nexus datastore connectivity
The compose file ships these key environment variables:

- `NEXUS_DATASTORE_ENABLED=true`
- `NEXUS_DATASTORE_NEXUS_JDBCURL=${NEXUS_JDBC_URL}` (defaults to
  `jdbc:postgresql://postgres:5432/nexus`)
- `NEXUS_DATASTORE_NEXUS_USERNAME=${NEXUS_DB_USER}`
- `NEXUS_DATASTORE_NEXUS_PASSWORD=${NEXUS_DB_PASSWORD}`

When Nexus starts it should log messages similar to `Datastore: connection pool
initialized`. If it fails, inspect:

```bash
docker exec -it nexus bash -lc 'cat /nexus-data/etc/datastore/nexus.properties'
```

## 5. Retrieve the initial admin password
Sonatype stores the first-use password under `/nexus-data/admin.password`.

```bash
docker exec nexus cat /nexus-data/admin.password
```

Log into the UI with username `admin` and that password, then follow the wizard
(you will be prompted to set a permanent password and decide whether anonymous
access should stay enabled).

## 6. Access the UI
The compose file publishes Nexus on host port `4926`. From a browser on the same
network, go to:

```
http://<server-ip>:4926/
```

For example, if you are on the same LAN referenced in `ip.txt`, use
`http://192.168.0.193:4926/` (the `server` entry). Replace the IP with whichever
host runs Docker. If DNS is configured you can use that instead.

## 7. Common follow-up commands
- `docker compose ps` — validate that both `nexus` and `nexus-postgres` are up.
- `docker exec -it nexus bash` — drop into the Nexus container to inspect logs or
  tweak configuration files.
- `docker exec -it nexus-postgres bash` — open a shell inside Postgres; handy
  when you need to edit `postgresql.conf` or inspect WAL files.
- `docker exec nexus tail -f /nexus-data/log/nexus.log` — follow logs without
  attaching via `docker compose logs`.

## 8. Storage layout: named volumes vs. host directories
The compose file uses Docker **named volumes** (`pgdata` and `nexus-data`). These
live under Docker's volume store (e.g., `/var/lib/docker/volumes/...`) and will
be deleted if you run `docker compose down --volumes` or `docker compose down
--rmi all --volumes`. If you want data to live in project-local folders instead,
switch to **bind mounts** so the files sit in the repo directory:

```yaml
services:
  postgres:
    volumes:
      - ./pgdata:/var/lib/postgresql/data

  nexus:
    volumes:
      - ./nexus-data:/nexus-data

volumes: {}
```

Notes:
- Create the directories first (`mkdir -p pgdata nexus-data`) so Docker doesn't
  create them as root with restrictive permissions.
- Bind mounts won't be removed by `docker compose down --volumes`; you can clean
  them manually if needed (`rm -rf pgdata nexus-data`).
- Named volumes are fine for disposable dev runs; bind mounts are better when
  you want to back up or inspect the files directly from the host.

## 9. Troubleshooting tips
- **Permission errors on volumes**: ensure the Docker user can write to the
  directories used for `pgdata` and `nexus-data`. On Linux, Docker usually
  handles this automatically, but if you pre-created the directories you may need
  `sudo chown 200:200` (Nexus runs as UID 200).
- **Postgres refuses connections**: double-check that `.env` is loaded before
  running `docker compose up`. Without the env vars, Compose will literally pass
  `${VAR}` strings to the containers.
- **Extension not found**: confirm you ran `CREATE EXTENSION pg_trgm;` while
  connected to the `nexus` database (not `postgres`). Use `\c nexus` inside psql
  to switch.

## 10. Cleaning up
To stop everything and remove volumes:

```bash
docker compose down --volumes
```

To remove the custom network (if Compose created one) run `docker network rm
homelab_default` once the services are down.

---

**Reference**: Sonatype's "Configure Nexus Repository to use external PostgreSQL
(source: Nexus Repository Manager 3 Datastore documentation). When in doubt,
search the official docs for "Nexus Repository datastore Postgres" for the most
up-to-date instructions.
