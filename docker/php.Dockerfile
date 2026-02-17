FROM php:8.4-fpm-alpine

# Устанавливаем нужные пакеты
RUN apk add --no-cache \
    curl \
    $PHPIZE_DEPS \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libxml2-dev \
    zip \
    unzip \
    git \
    oniguruma-dev \
    libzip-dev \
    linux-headers \
    fcgi \
    && pecl channel-update pecl.php.net \
    && pecl install xdebug \
    && docker-php-ext-enable xdebug \
    && docker-php-ext-install \
    pdo \
    pdo_mysql \
    mysqli \
    mbstring \
    xml \
    gd \
    bcmath \
    zip \
    && apk del $PHPIZE_DEPS

# Установка Composer (менеджер зависимостей PHP)
# Копируем бинарный файл из официального Docker-образа Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Устанавливаем рабочую директорию
WORKDIR /var/www/html

# Установка прав доступа (PHP-FPM в Alpine по умолчанию работает от www-data)
RUN chown -R www-data:www-data /var/www/html

# Экспонируем порт
EXPOSE 9000

# Запускаем PHP-FPM
CMD ["php-fpm", "-F"]
