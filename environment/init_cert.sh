#!/bin/bash

DOMAIN="bitcoder.ru"
NGINX_CONF_DIR="nginx/conf"
NGINX_CONF_FILE="${NGINX_CONF_DIR}/${DOMAIN}.conf"

# Проверить, существует ли конфигурационный файл
if [ -f "$NGINX_CONF_FILE" ]; then
    echo "Конфигурационный файл $NGINX_CONF_FILE уже существует. Скрипт завершен."
    exit 0
fi

# Проверить, запущен ли Docker Compose
if docker-compose ps | grep -q "Up"; then
    echo "Docker Compose запущен, останавливаем контейнеры..."
    docker-compose down --rmi all
else
    echo "Docker Compose не запущен, продолжаем..."
fi

# Создать начальный конфигурационный файл для nginx
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

# Выпустить сертификат
docker-compose run --rm certbot certonly --webroot -w /var/www/certbot --force-renewal --email letsencrypt@bitcoder.ru -d $DOMAIN --agree-tos

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
        proxy_pass http://backend:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL

    # Перезапустить nginx для применения изменений
    docker-compose up -d
else
    echo "Ошибка при выпуске сертификата для домена $DOMAIN"
fi