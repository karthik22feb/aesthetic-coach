# Local development image -- see docs/12-deployment-guide.md, section 2 (Development Environment)
# Production image (multi-stage, opcode-cached) is built separately per section 4 when Deployment (module 15) lands.
FROM php:8.3-fpm-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends         git unzip libzip-dev libpng-dev libonig-dev     && docker-php-ext-install pdo_mysql zip     && pecl install redis && docker-php-ext-enable redis     && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

EXPOSE 8000

# vendor/ is bind-mounted from the host in dev; installing here only matters
# on a fresh clone where composer install hasn't run natively yet.
CMD ["sh", "-c", "[ -d vendor ] || composer install --no-interaction --no-progress; php artisan serve --host=0.0.0.0 --port=8000"]
