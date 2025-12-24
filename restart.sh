#!/bin/bash

source ./apps/.env
docker compose -f traefik/docker-compose.yml down
docker compose -f traefik/docker-compose.yml up -d
# docker compose -f observability/docker-compose.yml down
# docker compose -f observability/docker-compose.yml up -d
# docker compose -f cloudflare/docker-compose.yml down
# docker compose -f cloudflare/docker-compose.yml up -d


# docker compose -f apps/docker-compose.yml down
# docker compose -f apps/docker-compose.yml up -d



