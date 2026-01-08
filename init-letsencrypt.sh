#!/bin/bash

# init-letsencrypt.sh - Initialize Let's Encrypt SSL certificates
# Based on https://github.com/wmnnd/nginx-certbot

set -e

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | xargs)
fi

# Configuration
domains=($DOMAIN)
email=$CERTBOT_EMAIL
data_path="./certbot"
rsa_key_size=4096
staging=0 # Set to 1 for testing to avoid rate limits

# Check if required environment variables are set
if [ -z "$DOMAIN" ] || [ -z "$CERTBOT_EMAIL" ]; then
    echo "Error: DOMAIN and CERTBOT_EMAIL must be set in .env file"
    exit 1
fi

echo "### Creating required directories..."
mkdir -p "$data_path/conf/live/$DOMAIN"
mkdir -p "$data_path/www"

# Download TLS parameters if not present
if [ ! -e "$data_path/conf/options-ssl-nginx.conf" ] || [ ! -e "$data_path/conf/ssl-dhparams.pem" ]; then
    echo "### Downloading recommended TLS parameters..."
    curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "$data_path/conf/options-ssl-nginx.conf"
    curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "$data_path/conf/ssl-dhparams.pem"
fi

# Create dummy certificate for nginx to start
echo "### Creating dummy certificate for $DOMAIN..."
path="/etc/letsencrypt/live/$DOMAIN"
docker compose run --rm --entrypoint "\
    openssl req -x509 -nodes -newkey rsa:$rsa_key_size -days 1 \
        -keyout '$path/privkey.pem' \
        -out '$path/fullchain.pem' \
        -subj '/CN=localhost'" certbot

echo "### Starting nginx with dummy certificate..."
# Use HTTP-only config initially
cp nginx/app-http.conf.template nginx/app.conf.template.bak 2>/dev/null || true
docker compose up -d nginx

echo "### Deleting dummy certificate..."
docker compose run --rm --entrypoint "\
    rm -Rf /etc/letsencrypt/live/$DOMAIN && \
    rm -Rf /etc/letsencrypt/archive/$DOMAIN && \
    rm -Rf /etc/letsencrypt/renewal/$DOMAIN.conf" certbot

echo "### Requesting Let's Encrypt certificate for $DOMAIN..."

# Select appropriate email arg
case "$email" in
    "") email_arg="--register-unsafely-without-email" ;;
    *) email_arg="--email $email" ;;
esac

# Enable staging mode if needed
if [ $staging != "0" ]; then staging_arg="--staging"; fi

docker compose run --rm --entrypoint "\
    certbot certonly --webroot -w /var/www/certbot \
        $staging_arg \
        $email_arg \
        -d $DOMAIN \
        --rsa-key-size $rsa_key_size \
        --agree-tos \
        --force-renewal" certbot

# Restore SSL config and reload nginx
echo "### Switching to SSL configuration..."
mv nginx/app.conf.template.bak nginx/app.conf.template 2>/dev/null || true
docker compose exec nginx nginx -s reload

echo "### SSL certificate installed successfully!"
echo "### Your site should now be accessible at https://$DOMAIN"
