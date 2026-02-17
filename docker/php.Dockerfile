# ==============================================================================
# Dockerfile для PHP-FPM
# Базовый образ: PHP 8.4 на Alpine Linux (минималистичный и безопасный)
# Содержит: Xdebug, расширения для БД (PDO/MySQLi), Composer и утилиты
# ==============================================================================

FROM php:8.4-fpm-alpine

# Установка системных зависимостей и PHP-расширений
# PHPIZE_DEPS содержит инструменты для сборки (gcc, make, autoconf и др.)
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

# Настройка рабочей директории приложения
WORKDIR /var/www/html

# Установка прав доступа (PHP-FPM в Alpine по умолчанию работает от www-data)
RUN chown -R www-data:www-data /var/www/html

# Экспонируем порт (9000 для TCP)
EXPOSE 9000

# Запуск PHP-FPM в фоновом режиме (флаг -F заставляет его работать на переднем плане для Docker)
CMD ["php-fpm", "-F"]
