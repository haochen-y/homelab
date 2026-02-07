# homelab
Homelab stack running via Docker Compose with a shared reverse proxy network and
service-specific compose files. Most services are exposed through Traefik on the
`homelab_proxy` network and tied to `*.bigmaninc.party` hostnames.

## Directory Map
- `traefik/`: reverse proxy, dashboard, Docker provider via socket-proxy
- `apps/`: core apps (Nexus + Postgres, Forgejo, whoami)
- `ai/`: n8n, ollama, open-webui
- `observability/`: Prometheus, Grafana, Loki, Promtail
- `management/`: Portainer, Dockge
- `cloudflare/`: cloudflared tunnel
- `caddy/`: optional Caddy server
- `usefull_command.md`: host OS notes and tweaks
- `up.sh` / `down.sh` / `restart.sh`: helper scripts
- `ip.txt`: LAN IP notes

## High-Level Flow
- Traefik runs on `homelab_proxy`, discovers containers via Docker labels.
- Most services join `homelab_proxy` and use host-based routing.
- Observability scrapes Traefik and cloudflared metrics.
- AI stack uses an internal network plus a dedicated egress network.
- Cloudflare tunnel can target an internal-only Traefik entrypoint (`tunnel`)
  so selected services are not reachable from the LAN.

## Requirements
- Docker Engine + Docker Compose v2
- External Docker network `homelab_proxy`
- `.env` files:
  - `apps/.env`
  - `observability/.env`
  - `ai/.env`

Create the shared network once:

```bash
docker network create homelab_proxy
```

## Start / Stop
```bash
./up.sh
./down.sh
```

`restart.sh` is currently scoped to observability only.

## Notable Services
- Nexus + Postgres: `apps/docker-compose.yml`
  - Repos: Docker, PyPI, Conda, Hugging Face, APT
  - Setup docs:
    - `apps/NEXUS_SERVER_SETUP.md`
    - `apps/NEXUS_CLIENT_SETUP.md`
- Forgejo: `apps/docker-compose.yml` + `apps/FORGEJO_SETUP.md`
- Observability: Prometheus, Grafana, Loki, Promtail
- AI: n8n, Ollama, Open WebUI
- Management: Portainer, Dockge
- Automation: `automation/docker-compose.yml` (tapo-rest via tunnel-only entrypoint)

## Notes / Gotchas
- `traefik/certs/acme.json` contains TLS state and should be protected.
- Most services are routed over HTTP entrypoint `web` unless otherwise noted.
- Some services are intended to be Tailscale-only via the `ts-only` middleware.
- Services using the `tunnel` entrypoint are only reachable via Cloudflare
  tunnel (`http://traefik:8085`) and are not exposed on LAN.
