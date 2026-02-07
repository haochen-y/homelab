# agent
Agent guidance for this homelab repo. Keep changes small, prefer Compose edits,
and preserve existing conventions.

## Style
- Keep docs short and practical.
- Prefer simple headings and flat lists (no nested bullets).
- Avoid copying secrets from `.env` or `traefik/certs/acme.json`.

## Where To Look
- `README.md` for the summary and quick start.
- `apps/`, `ai/`, `observability/`, `management/`, `cloudflare/`, `caddy/`,
  `traefik/` for compose files.
- `usefull_command.md` for host OS notes.
- `ip.txt` for LAN IP notes.

## How To Operate
- Most services are exposed through Traefik on the `homelab_proxy` network.
- If you add a service, attach it to `homelab_proxy` and add Traefik labels.
- For internal-only services, use a dedicated internal network and avoid labels.
- When touching observability configs, keep scrape targets in sync with running
  services and their ports.

## Safe Defaults
- Do not edit `traefik/certs/acme.json`.
- Do not inline secrets; reference `.env` variables instead.
- Keep external network name as `homelab_proxy` unless explicitly requested.

## Common Tasks
- Start stack: `./up.sh`
- Stop stack: `./down.sh`
- Restart observability: `./restart.sh`

## Adding A New Service
1. Pick the right compose folder.
2. Add service + volumes + networks.
3. Add Traefik labels if it should be exposed.
4. Update `README.md` if it changes the stack summary.
