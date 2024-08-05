#!/bin/bash

# Проверка аргументов
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 DOMAIN PROXY_PASS"
    exit 1
fi

DOMAIN="$1"
PROXY_PASS="$2"
EMAIL="letsencrypt.certs@bitcoder.ru"
NGINX_CONF_DIR="nginx/conf"
NGINX_CONF_FILE="${NGINX_CONF_DIR}/${DOMAIN}.conf"

if [ ! -d "$NGINX_CONF_DIR" ]; then
    mkdir -p "$NGINX_CONF_DIR"
fi

# Проверить, существует ли конфигурационный файл
if [ -f "$NGINX_CONF_FILE" ]; then
    echo "Конфигурационный файл $NGINX_CONF_FILE уже существует. Скрипт завершен."
    exit 0
else
    cat <<EOL > "$NGINX_CONF_FILE"
server {
    listen 80;
    server_name $DOMAIN;
    server_tokens off;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}
EOL
fi

# Проверить, запущен ли Docker Compose
if docker-compose ps | grep -q "Up"; then
    echo "Docker Compose запущен, останавливаем контейнеры..."
    docker-compose down --rmi all
fi

docker-compose up -d

# Выпустить сертификат
docker-compose run --rm certbot certonly --webroot --webroot-path /var/www/certbot/ --email $EMAIL --agree-tos -d $DOMAIN

# Проверить успешность выполнения команды
if [ $? -eq 0 ]; then
    echo "Сертификат успешно выпущен для домена $DOMAIN"

    # Создать новый конфигурационный файл для nginx
    cat <<EOL > "$NGINX_CONF_FILE"
server {
    listen 80;
    server_name $DOMAIN;
    server_tokens off;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}
server {
    listen 443 ssl;
    server_name $DOMAIN;
    server_tokens off;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    location / {
        proxy_pass http://$PROXY_PASS;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL

    # Перезапустить nginx для применения изменений
    docker-compose restart nginx
else
    echo "Ошибка при выпуске сертификата для домена $DOMAIN"
fi
