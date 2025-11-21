.PHONY: help up down restart extract load-redis dbt-run dbt-test clean logs

help:
	@echo "Available commands:"
	@echo "  make up          - Start all services"
	@echo "  make down        - Stop all services"
	@echo "  make restart     - Restart all services"
	@echo "  make extract     - Extract weather data"
	@echo "  make load-redis  - Load data to Redis"
	@echo "  make dbt-run     - Run dbt models"
	@echo "  make dbt-test    - Test dbt models"
	@echo "  make pipeline    - Run complete pipeline"
	@echo "  make clean       - Clean up volumes and containers"
	@echo "  make logs        - Show logs"

up:
	docker compose up -d
	@echo "Waiting for services to be ready..."
	@sleep 10

down:
	docker compose down

restart: down up

extract:
	docker compose exec dbt python /usr/app/scripts/extract_weather.py

load-redis:
	docker compose exec dbt python /usr/app/scripts/postgres_to_redis.py

dbt-run:
	docker compose exec dbt sh -c "cd /usr/app/dbt_project && dbt run"

dbt-test:
	docker compose exec dbt sh -c "cd /usr/app/dbt_project && dbt test"

dbt-debug:
	docker compose exec dbt sh -c "cd /usr/app/dbt_project && dbt debug"

pipeline: extract dbt-run load-redis
	@echo "Pipeline completed successfully!"

clean:
	docker compose down -v
	docker system prune -f

logs:
	docker compose logs -f

shell-dbt:
	docker compose exec dbt /bin/bash

shell-postgres:
	docker compose exec postgres psql -U weather_user -d weather_db

shell-redis:
	docker compose exec redis redis-cli
