UV ?= uv
UV_CACHE_DIR ?= .uv-cache
TEST_DATABASE_URL ?= postgresql://kitchen_test:kitchen-test-only@127.0.0.1:5433/kitchen_test

export UV_CACHE_DIR

.PHONY: sync lock-check format format-check lint typecheck test integration-test verify migrate run clean

sync:
	$(UV) sync --frozen

lock-check:
	$(UV) lock --check

format:
	$(UV) run ruff format .
	$(UV) run ruff check --fix .

format-check:
	$(UV) run ruff format --check .
	$(UV) run ruff check .

lint:
	$(UV) run ruff check .

typecheck:
	$(UV) run mypy src tests

test:
	$(UV) run pytest -m "not integration"

integration-test:
	docker compose up -d --wait postgres-test
	APP_ENV=testing DATABASE_URL=$(TEST_DATABASE_URL) $(UV) run pytest -m integration

verify: lock-check format-check typecheck test

migrate:
	$(UV) run alembic upgrade head

run:
	$(UV) run kitchen-server

clean:
	docker compose down --remove-orphans
