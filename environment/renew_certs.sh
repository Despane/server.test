#!/bin/bash

# Обновляем сертификаты
docker-compose -f /home/admin/environment/docker-compose.yml run --rm certbot renew --force-renewal

# Перезагружаем nginx
docker-compose -f /home/admin/environment/docker-compose.yml restart nginx