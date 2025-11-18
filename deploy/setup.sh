#!/bin/bash
set -xe

echo "Starting initial setup..."

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

docker compose up -d postgres caddy mailserver

echo "Waiting for mailserver..."
until docker compose exec -T mailserver ps > /dev/null 2>&1; do
  echo "Mailserver not ready yet, waiting..."
  sleep 5
done

echo "Creating initial mail account..."
docker compose exec -T mailserver setup email add ${MAIL_USER}@${MAIL_DOMAIN_NAME} ${MAIL_PASS}

echo "Waiting for database..."
until docker compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; do
  echo "Postgres not ready yet, waiting..."
  sleep 5
done

echo "Running migrations..."
docker compose run --rm compritas ./bin/migrate

echo "Starting application..."
docker compose up -d compritas

echo "Setup completed!"
docker compose ps

