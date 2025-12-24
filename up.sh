source ./apps/.env
docker compose -f traefik/docker-compose.yml up -d
docker compose -f apps/docker-compose.yml up -d

