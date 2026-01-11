docker compose -f traefik/docker-compose.yml down
docker compose -f apps/docker-compose.yml down
docker compose -f cloudflare/docker-compose.yml down
docker compose -f observability/docker-compose.yml down
docker compose -f ai/docker-compose.yml down



