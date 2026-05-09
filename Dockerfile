FROM php:8.2-apache

# Install dependencies
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
    npm

# PHP extensions
RUN docker-php-ext-install pdo pdo_mysql mbstring zip exif pcntl

# Enable apache rewrite
RUN a2enmod rewrite

# Install composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Working directory
WORKDIR /var/www/html

# Copy project
COPY . .

# Install composer dependencies
RUN composer install --no-dev --optimize-autoloader

# Install node modules
RUN npm install

# Build frontend
RUN npm run build

# Laravel setup
RUN cp .env.example .env || true

RUN php artisan key:generate || true

# Create writable directories
RUN mkdir -p storage/framework/cache
RUN mkdir -p storage/framework/sessions
RUN mkdir -p storage/framework/views
RUN mkdir -p storage/logs
RUN mkdir -p bootstrap/cache

# Permissions
RUN chmod -R 777 storage bootstrap/cache

# Clear cache
RUN php artisan config:clear || true
RUN php artisan cache:clear || true
RUN php artisan view:clear || true
RUN php artisan route:clear || true

# Temp directory
ENV TMPDIR=/tmp

# Apache config
RUN sed -i 's!/var/www/html!/var/www/html/public!g' \
    /etc/apache2/sites-available/000-default.conf

EXPOSE 80

CMD ["apache2-foreground"]