#!/bin/bash
set -e

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

echo "Generating DKIM keys for domain ${DOMAIN_NAME}"
docker compose exec -T mailserver setup config dkim

echo "Waiting for database..."
until docker compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; do
  echo "Postgres not ready yet, waiting..."
  sleep 5
done

echo "Running migrations..."
docker compose run --rm compritas ./bin/migrate

echo "Starting application..."
docker compose up -d compritas

echo "Setup completed."
echo ""

echo "User created: ${MAIL_USER}@${MAIL_DOMAIN_NAME}"
echo "DKIM keys generated in volume 'mail_config' at /tmp/docker-mailserver/opendkim/keys/${MAIL_DOMAIN_NAME}/mail.txt"
echo "Displaying DKIM public key (add this as TXT record in DNS):"

echo ""

docker compose exec -T mailserver cat /tmp/docker-mailserver/opendkim/keys/${MAIL_DOMAIN_NAME}/mail.txt

echo ""

echo "DNS configuration instructions:"
echo "1. Create an A record:"
echo "   mail.${MAIL_DOMAIN_NAME}.   IN A   <your-server-public-IP>"
echo ""
echo "2. Create an MX record for your domain:"
echo "   ${MAIL_DOMAIN_NAME}.   IN MX 10 mail.${MAIL_DOMAIN_NAME}."
echo ""
echo "3. Create an SPF record (TXT):"
echo "   ${MAIL_DOMAIN_NAME}.   IN TXT \"v=spf1 mx ~all\""
echo ""
echo "4. Add the DKIM TXT record using the content shown above from mail.txt"
echo ""
echo "5. (Optional but recommended) Add a DMARC record:"
echo "   _dmarc.${MAIL_DOMAIN_NAME}.   IN TXT \"v=DMARC1; p=quarantine; rua=mailto:postmaster@${MAIL_DOMAIN_NAME}\""
