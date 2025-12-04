#!/bin/bash
set -e

echo "Pulling latest images..."
docker compose pull compritas-blue compritas-green

echo "Running migrations..."
docker compose run --rm compritas-blue /app/bin/migrate

echo "Updating compritas-blue..."
docker compose up -d --no-deps compritas-blue
echo "Waiting for health check..."
sleep 40

echo "Updating compritas-green..."
docker compose up -d --no-deps compritas-green
echo "Waiting for health check..."
sleep 40

echo "Cleaning up old images..."
docker image prune -f --filter "dangling=true"

echo "Deploy completed!"
docker compose ps

