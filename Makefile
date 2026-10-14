# TerraReality developer entry points. Run `make help`.
SHELL := /bin/bash
COMPOSE := docker compose -f infra/dev/docker-compose.yml
API := services/api
VISION := services/vision
-include .env
export

.PHONY: help setup up down dev migrate seed gen gen-check test test-go test-web test-site test-mobile test-vision lint e2e build images clean-db

help: ## List targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

setup: ## Install all dependencies (npm, Go, Python venv, Flutter)
	@[ -f .env ] || cp .env.example .env
	npm install
	cd $(API) && go mod download
	cd $(VISION) && python3 -m venv .venv && .venv/bin/pip install -q -e '.[dev]'
	cd apps/mobile && flutter pub get && flutter gen-l10n
	cd apps/web && npm run i18n

up: ## Start docker dependencies
	$(COMPOSE) up -d --build --wait db centrifugo mailpit
	$(COMPOSE) up -d temporal s3 imgproxy

down: ## Stop docker dependencies
	$(COMPOSE) down

dev: ## Start everything (deps, api, worker, vision, web, site)
	./scripts/dev.sh

migrate: ## Apply DB migrations (goose + River)
	cd $(API) && go run ./cmd/migrate up

seed: ## Create dev accounts staff@terra.local and owner@terra.local (password terra-dev-password)
	cd $(API) && go run ./cmd/terractl seed-dev

gen: ## Regenerate code from contracts (Go server, sqlc, TS + Dart clients, l10n)
	cd $(API) && go tool oapi-codegen -config oapi-codegen.yaml ../../packages/contracts/openapi.yaml
	cd $(API) && sqlc generate
	npm run gen
	cd apps/mobile && flutter gen-l10n

gen-check: gen ## Fail if generated code is out of date
	git diff --exit-code -- $(API)/internal/api/gen $(API)/internal/db packages/contracts/ts packages/contracts/dart

test: test-go test-web test-site test-mobile test-vision ## Run all unit/integration tests

test-go:
	cd $(API) && go test -race ./...

test-web:
	npm run check -w @terra/contracts
	npm run check -w web
	npm run test -w web

test-site:
	npm run check -w site

test-mobile:
	cd apps/mobile && flutter analyze && flutter test

test-vision:
	cd $(VISION) && .venv/bin/pytest -q

lint: ## Linters (go vet, staticcheck, prettier+eslint, ruff, flutter analyze)
	cd $(API) && go vet ./... && go tool staticcheck ./...
	npm run lint -w web
	cd $(VISION) && .venv/bin/ruff check . && .venv/bin/ruff format --check .
	cd apps/mobile && flutter analyze

e2e: ## Playwright E2E against a running api + worker (make dev in another terminal)
	cd $(API) && go run ./cmd/terractl seed-dev >/dev/null
	cd apps/web && npx playwright test

build: ## Build Go binaries and web/site bundles
	cd $(API) && go build -o bin/ ./cmd/...
	npm run build

images: ## Build production container images
	docker build -f $(API)/Dockerfile -t terra/api $(API)
	docker build -f apps/web/Dockerfile -t terra/web .
	docker build -t terra/vision $(VISION)

clean-db: ## Drop and recreate the dev database volume (DESTROYS local data)
	$(COMPOSE) down -v
