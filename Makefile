# ==============================================================================
# УПРАВЛЕНИЕ СРЕДОЙ РАЗРАБОТКИ (Makefile)
# ==============================================================================
# Упрощает запуск Docker-контейнеров и выполнение типичных команд.
# Используйте "make help" для просмотра всех доступных команд.

.PHONY: help up down restart build rebuild logs logs-php logs-httpd logs-mysql logs-phpmyadmin status shell-php shell-httpd shell-mysql clean clean-all setup info test check-files xdebug-up xdebug-down permissions composer-install composer-update composer-require dev-reset

# Настройки оформления вывода в терминал
YELLOW=\033[0;33m
GREEN=\033[0;32m
RED=\033[0;31m
NC=\033[0m # No Color

# Загрузка переменных окружения из .env (если он существует)
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

# Порты по умолчанию (если не заданы в .env)
HTTPD_PORT ?= 80
MYSQL_PORT ?= 3306
PHPMYADMIN_PORT ?= 8080

# Имена контейнеров (должны совпадать с docker-compose.yml)
PHP_CONTAINER=php-httpd-tcp
HTTPD_CONTAINER=httpd-tcp
MYSQL_CONTAINER=mysql-httpd-tcp
PHPMYADMIN_CONTAINER=phpmyadmin-httpd-tcp

# Цель по умолчанию
help: ## Показать справку по всем командам
	@echo "$(YELLOW)PHP-Httpd-TCP: Справка по командам$(NC)"
	@echo "=================================================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' Makefile | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Сервисы будут доступны по адресам:$(NC)"
	@echo "  • Web Server:  http://localhost:$(HTTPD_PORT)"
	@echo "  • phpMyAdmin:  http://localhost:$(PHPMYADMIN_PORT)"

check-files: ## Проверить наличие конфигурационных файлов перед запускуом
	@echo "$(YELLOW)Проверка файлов конфигурации...$(NC)"
	@test -f .env || (echo "$(RED)✗ .env не найден. Скопируйте .env.example в .env$(NC)" && exit 1)
	@test -f docker-compose.yml || (echo "$(RED)✗ docker-compose.yml не найден$(NC)" && exit 1)
	@echo "$(GREEN)✓ Основные файлы на месте$(NC)"

up: check-files ## Запустить все сервисы в фоновом режиме
	@echo "$(YELLOW)Запуск контейнеров...$(NC)"
	docker compose up -d
	@echo "$(GREEN)✓ Среда готова к работе$(NC)"

down: ## Остановить и удалить все контейнеры текущего проекта
	@echo "$(YELLOW)Остановка контейнеров...$(NC)"
	docker compose down
	@echo "$(GREEN)✓ Контейнеры остановлены$(NC)"

restart: ## Перезапустить все сервисы
	@echo "$(YELLOW)Перезапуск...$(NC)"
	docker compose restart

build: ## Собрать Docker-образы (без кэширования)
	@echo "$(YELLOW)Сборка образов...$(NC)"
	docker compose build

rebuild: ## Полная пересборка образов (игнорируя кэш Docker)
	@echo "$(YELLOW)Пересборка (без кэша)...$(NC)"
	docker compose build --no-cache

xdebug-up: check-files ## Запустить стек с включенным Xdebug
	@echo "$(YELLOW)Запуск с Xdebug (режим отладки)...$(NC)"
	docker compose -f docker-compose.yml -f docker-compose.xdebug.yml up -d
	@echo "$(GREEN)✓ Сервисы с Xdebug запущены$(NC)"

xdebug-down: ## Выключить Xdebug (вернуться к обычному режиму)
	@echo "$(YELLOW)Выключение Xdebug...$(NC)"
	docker compose -f docker-compose.yml -f docker-compose.xdebug.yml down

logs: ## Просмотр логов всех контейнеров (в реальном времени)
	docker compose logs -f

logs-php: ## Логи только для PHP-FPM
	docker compose logs -f $(PHP_CONTAINER)

logs-httpd: ## Логи только для Apache (Httpd)
	docker compose logs -f $(HTTPD_CONTAINER)

logs-mysql: ## Логи только для MySQL
	docker compose logs -f $(MYSQL_CONTAINER)

logs-phpmyadmin: ## Логи только для phpMyAdmin
	docker compose logs -f $(PHPMYADMIN_CONTAINER)

status: ## Показать статус и порты запущенных контейнеров
	@echo "$(YELLOW)Статус контейнеров:$(NC)"
	@docker compose ps

shell-php: ## Войти в терминал контейнера PHP
	docker compose exec $(PHP_CONTAINER) sh

shell-httpd: ## Войти в терминал контейнера Apache
	docker compose exec $(HTTPD_CONTAINER) sh

shell-mysql: ## Войти в терминал контейнера MySQL
	docker compose exec $(MYSQL_CONTAINER) mysql -uroot -p

info: ## Показать информацию о проекте
	@echo "$(YELLOW)PHP-Httpd-TCP Development Environment$(NC)"
	@echo "======================================"
	@echo "$(GREEN)Сервисы:$(NC)"
	@echo "  • PHP-FPM 8.4 (Alpine)"
	@echo "  • Apache HTTP Server 2.4"
	@echo "  • MySQL 8.4"
	@echo "  • phpMyAdmin"
	@echo ""
	@echo "$(GREEN)Структура:$(NC)"
	@echo "  • public/           - публичные файлы (DocumentRoot)"
	@echo "  • docker/httpd/     - конфигурация Apache"
	@echo "  • docker/php/       - конфигурация PHP (php.ini)"
	@echo "  • .env              - переменные окружения"
	@echo ""
	@echo "$(GREEN)Порты:$(NC)"
	@echo "  • 80   - Apache"
	@echo "  • 3306 - MySQL Database"
	@echo "  • 8080 - phpMyAdmin"

test: ## Проверить работу сервисов
	@echo "$(YELLOW)Проверка работы сервисов...$(NC)"
	@echo -n "Apache (http://localhost:$(HTTPD_PORT)): "
	@curl -fsS -o /dev/null -w "%{http_code}" "http://localhost:$(HTTPD_PORT)" \
	&& echo " $(GREEN)✓$(NC)" || echo " $(RED)✗$(NC)"
	@echo -n "phpMyAdmin (http://localhost:$(PHPMYADMIN_PORT)): "
	@curl -fsS -o /dev/null -w "%{http_code}" "http://localhost:$(PHPMYADMIN_PORT)" \
	&& echo " $(GREEN)✓$(NC)" || echo " $(RED)✗$(NC)"
	@echo -n "MySQL (mysqladmin ping): "
	@docker compose exec -T $(MYSQL_CONTAINER) mysqladmin ping -uroot -p"$$MYSQL_ROOT_PASSWORD" --silent \
	&& echo " $(GREEN)✓$(NC)" || echo " $(RED)✗$(NC)"
	@echo "$(YELLOW)Статус контейнеров:$(NC)"
	@docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

clean: ## Удалить контейнеры и очистить тома (включая БД!)
	@echo "$(YELLOW)Очистка (контейнеры + тома)...$(NC)"
	docker compose down -v

clean-all: ## Полная очистка: контейнеры, тома и образы
	@echo "$(YELLOW)Полная очистка (образы + тома)...$(NC)"
	docker compose down -v --rmi all

dev-reset: clean-all build up ## Полный сброс и перезапуск всей среды разработки

permissions: ## Исправить права доступа для папки public/ (755)
	@chmod -R 755 public/

composer-install: ## Установить PHP-зависимости (из composer.json)
	docker compose exec $(PHP_CONTAINER) composer install

composer-update: ## Обновить PHP-зависимости
	docker compose exec $(PHP_CONTAINER) composer update

# Пример: make composer-require PACKAGE=monolog/monolog
composer-require: ## Установить новый PHP-пакет (укажите PACKAGE=...)
	docker compose exec $(PHP_CONTAINER) composer require $(PACKAGE)

.DEFAULT_GOAL := help
