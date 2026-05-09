# ===== Base Image =====
FROM php:8.2-apache

# ===== Environment Setup =====
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public \
    TMPDIR=/tmp

# ===== Install System Dependencies =====
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    zip \
    curl \
    libzip-dev \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    nodejs \
    npm \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ===== Install PHP Extensions =====
RUN docker-php-ext-install pdo pdo_mysql mbstring zip exif pcntl

# ===== Enable Apache Modules =====
RUN a2enmod rewrite

# ===== Install Composer =====
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# ===== Set Working Directory =====
WORKDIR /var/www/html

# ===== Copy Application Files =====
COPY . .

# ===== Laravel Writable Directories =====
RUN mkdir -p storage/framework/cache \
    storage/framework/sessions \
    storage/framework/views \
    storage/logs \
    bootstrap/cache

# Set proper ownership and permissions for Apache user
RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Ensure log file exists
RUN touch storage/logs/laravel.log \
    && chown www-data:www-data storage/logs/laravel.log

# ===== Composer & Node Setup =====
RUN composer install --no-dev --optimize-autoloader
RUN npm install
RUN npm run build

# ===== Laravel Environment =====
RUN cp .env.example .env || true
RUN php artisan key:generate || true

# ===== Clear Caches =====
RUN php artisan config:clear || true
RUN php artisan cache:clear || true
RUN php artisan view:clear || true
RUN php artisan route:clear || true

# ===== Apache Configuration =====
RUN sed -i "s!/var/www/html!${APACHE_DOCUMENT_ROOT}!g" /etc/apache2/sites-available/000-default.conf

# ===== Expose Port & Start Apache =====
EXPOSE 80
CMD ["apache2-foreground"]