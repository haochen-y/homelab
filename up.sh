source ./apps/.env
source ./observability/.env
source ./ai/.env


docker compose -f traefik/docker-compose.yml up -d
docker compose -f apps/docker-compose.yml up -d
docker compose -f cloudflare/docker-compose.yml up -d
docker compose -f observability/docker-compose.yml up -d


