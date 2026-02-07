# PHP-Httpd-TCP — учебный стек на Docker (современная замена XAMPP/MAMP/Open Server)

Простая, воспроизводимая и «говорящая» среда для изучения PHP и его экосистемы. Стек собирается из контейнеров Docker и предназначен для локальных экспериментов.

Важное: этот проект предназначен исключительно для обучения, практики и ознакомления. Не используйте его в проде.

## Что внутри (архитектура)

Сервисы docker-compose.yml:
- PHP-FPM 8.4 (контейнер php-httpd-tcp) — выполняет PHP, порт 9000 (внутренний), Xdebug установлен, управляется переменными окружения.
- Apache HTTP Server 2.4 (контейнер httpd-tcp) — отдаёт статику и проксирует .php в PHP-FPM; доступен на http://localhost:80.
- MySQL 8.4 (контейнер mysql-httpd-tcp) — база данных на localhost:3306, данные в именованном томе mysql-data.
- phpMyAdmin (контейнер phpmyadmin-httpd-tcp) — веб-интерфейс MySQL на http://localhost:8080.

Здоровье (healthchecks):
- PHP-FPM — проверка fastcgi (cgi-fcgi -connect localhost:9000).
- Apache — HTTP-запрос к http://localhost/.
- MySQL — mysqladmin ping.
- phpMyAdmin — HTTP-запрос к http://localhost/.

Порядок старта: httpd-tcp ожидает, когда php-httpd-tcp станет healthy.

## Структура репозитория (актуальная)

```
php-httpd-tcp/
├── Makefile
├── README.md
├── .env.example
├── .env                        # Ваши локальные переменные окружения
├── docker/
│   ├── httpd/
│   │   ├── httpd.conf          # Конфиг Apache (проксирование в PHP-FPM)
│   │   ├── httpd.framework.conf # Альтернативный конфиг (Single Entry Point)
│   │   └── httpd.proxypass.conf # Legacy-конфиг (ProxyPassMatch)
│   ├── php/
│   │   └── php.ini             # Конфиг PHP (dev-настройки + Xdebug через env)
│   └── php.Dockerfile          # Образ PHP-FPM 8.4 (Alpine) + расширения + Xdebug + Composer
├── docker-compose.yml          # Основной стек: PHP-FPM, Apache, MySQL, phpMyAdmin
├── docker-compose.xdebug.yml   # Оверлей для включения Xdebug (mode=start)
└── public/                     # DocumentRoot (будет смонтирован в Apache и PHP-FPM)
    ├── index.html
    ├── index.php
    └── phpinfo.php
```

Обратите внимание: папки src/ и logs/ в данном репозитории отсутствуют. Для обучения достаточно размещать PHP-файлы в public/.

## Быстрый старт

Предпосылки:
- Docker 20.10+
- Docker Compose v2+

Шаги:
1) Клонируйте репозиторий и перейдите в каталог проекта.
2) Скопируйте пример env:
   - cp .env.example .env
   - при необходимости отредактируйте пароли/имена БД.
3) Запустите стек:
   - make up (или docker compose up -d)
4) Проверьте доступность:
   - Web: http://localhost
   - phpMyAdmin: http://localhost:8080 (сервер mysql-httpd-tcp)
   - MySQL: localhost:3306

Полезные команды Makefile:
- make up / make down / make restart — управление стеком
- make logs / make status — логи и статусы контейнеров
- make xdebug-up / make xdebug-down — запуск/остановка стека с включённым Xdebug
- make check-files — проверить, что все нужные файлы на месте

## Конфигурация

PHP (docker/php/php.ini):
- error_reporting=E_ALL, display_errors=On — удобно учиться на ошибках
- memory_limit=256M, upload_max_filesize=20M, post_max_size=20M
- opcache включён, validate_timestamps=1 (код обновляется сразу)
- Xdebug управляется через переменные окружения (см. ниже)

Apache (docker/httpd/httpd.conf):
- mod_proxy_fcgi проксирует .php в php-httpd-tcp:9000
- AllowOverride None в /var/www/html — .htaccess отключён (для простоты и скорости)

Альтернативные конфиги Apache (docker/httpd/):
- httpd.framework.conf — режим Single Entry Point для фреймворков
- httpd.proxypass.conf — legacy-режим через ProxyPassMatch

Docker-образ PHP (docker/php.Dockerfile):
- База: php:8.4-fpm-alpine
- Установлены расширения: pdo, pdo_mysql, mysqli, mbstring, xml, gd, bcmath, zip
- Установлен Xdebug (через pecl), Composer, fcgi (для healthcheck)

## Переменные окружения (.env)

Минимальный набор (см. .env.example):
- MYSQL_ROOT_PASSWORD — пароль root для MySQL
- PMA_HOST=mysql-httpd-tcp — хост БД для phpMyAdmin
- HTTPD_PORT, MYSQL_PORT, PHPMYADMIN_PORT — порты сервисов
- XDEBUG_MODE, XDEBUG_START, XDEBUG_CLIENT_HOST — опционально для Xdebug

## Xdebug: как включить

По умолчанию Xdebug установлен, но выключен (переменные не заданы). Включить можно двумя способами:

Вариант A: оверлейный compose-файл
- make xdebug-up
  (эквивалент docker compose -f docker-compose.yml -f docker-compose.xdebug.yml up -d)
- Внутри php.ini используются переменные XDEBUG_MODE=debug и XDEBUG_START=yes.

Вариант B: задать переменные в .env и перезапустить php-контейнер
- XDEBUG_MODE=debug
- XDEBUG_START=yes
- XDEBUG_CLIENT_HOST=host.docker.internal
- затем docker compose up -d --no-deps php-httpd-tcp

IDE: подключение по Xdebug 3 на порт 9003, client_host=host.docker.internal.

## Рабочие директории и монтирование

- public/ монтируется в /var/www/html одновременно в PHP-FPM и Apache — любые изменения видны сразу.
- docker/php/php.ini монтируется в /usr/local/etc/php/conf.d/local.ini (только чтение).
- Для MySQL используется именованный том mysql-data (персистентные данные).

## Подключение к MySQL из PHP (пример)

```
<?php
$host = 'mysql-httpd-tcp';
$dbname = 'your-db-name';
$user = 'your-user';
$pass = 'your-user-password';
$pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $user, $pass);
```

## Решение проблем

Порты заняты:
- Измените привязку в docker-compose.yml, например 8080:80 для Apache.

Контейнеры не стартуют по порядку:
- Проверьте healthchecks командой docker compose ps; httpd-tcp зависит от healthy php-httpd-tcp.

Xdebug не подключается:
- Проверьте, что используете порт 9003 в IDE, и что XDEBUG_MODE/START заданы (compose.xdebug.yml или env/.env).

Полная очистка и пересборка:
- make clean или make clean-all; затем make rebuild и make up.

## Дисклеймер

Проект создан для обучения и экспериментов с PHP-стеком. Не предназначен для production-использования или оценки производительности.
