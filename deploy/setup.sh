#!/bin/bash
set -xe

echo "Starting initial setup..."

docker compose up -d postgres caddy compritas

echo "Waiting for database to be ready..."
until docker compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; do
  echo "Postgres not ready yet, waiting..."
  sleep 5
done

echo "Waiting for app healthcheck..."
until [ "$(docker inspect --format='{{.State.Health.Status}}' compritas-compritas-1)" = "healthy" ]; do
  echo "App not healthy yet, waiting..."
  sleep 5
done

echo "Running migrations..."
docker compose run --rm compritas ./bin/migrate

echo "Setup completed!"
docker compose ps

