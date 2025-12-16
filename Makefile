
# Makefile for VNDG-ME Rails Application

# Variables
DOCKER_IMAGE_NAME = vndgme
DOCKER_TAG = latest
DOCKER_REGISTRY = 
RUBY_VERSION = 3.4.2
RAILS_ENV = development

# Default target
.DEFAULT_GOAL := help

# Setup and Installation
.PHONY: setup
setup:
	@echo "Setting up the Rails application..."
	bundle install
	bin/rails db:prepare
	bin/rails db:seed

.PHONY: install
install:
	@echo "Installing dependencies..."
	bundle install

# Development
.PHONY: dev
dev:
	@echo "Starting development server..."
	bin/dev

.PHONY: server
server:
	@echo "Starting Rails server..."
	bin/rails server

.PHONY: console
console:
	@echo "Starting Rails console..."
	bin/rails console

.PHONY: routes
routes:
	@echo "Displaying application routes..."
	bin/rails routes

# Database
.PHONY: db-create
db-create:
	@echo "Creating databases..."
	bin/rails db:create

.PHONY: db-migrate
db-migrate:
	@echo "Running database migrations..."
	bin/rails db:migrate

.PHONY: db-rollback
db-rollback:
	@echo "Rolling back database migration..."
	bin/rails db:rollback

.PHONY: db-seed
db-seed:
	@echo "Seeding database..."
	bin/rails db:seed

.PHONY: db-reset
db-reset:
	@echo "Resetting database..."
	bin/rails db:reset

.PHONY: db-drop
db-drop:
	@echo "Dropping databases..."
	bin/rails db:drop

# Testing
.PHONY: test
test:
	@echo "Running RSpec tests..."
	bundle exec rspec

.PHONY: test-fast
test-fast:
	@echo "Running RSpec tests in parallel..."
	bundle exec parallel_rspec spec/

.PHONY: test-coverage
test-coverage:
	@echo "Running tests with coverage..."
	COVERAGE=true bundle exec rspec

# Code Quality
.PHONY: lint
lint:
	@echo "Running RuboCop..."
	bundle exec rubocop

.PHONY: lint-fix
lint-fix:
	@echo "Running RuboCop with auto-correct..."
	bundle exec rubocop -a

.PHONY: security
security:
	@echo "Running security checks..."
	bundle exec brakeman
	bundle exec bundle-audit

# Assets
.PHONY: assets-precompile
assets-precompile:
	@echo "Precompiling assets..."
	bin/rails assets:precompile

.PHONY: assets-clean
assets-clean:
	@echo "Cleaning compiled assets..."
	bin/rails assets:clean

# Docker commands
.PHONY: build
build:
	@echo "Building Docker image..."
	docker build -t $(DOCKER_IMAGE_NAME):$(DOCKER_TAG) .

.PHONY: run
run:
	@echo "Running Docker container..."
	docker run -d -p 80:80 --name $(DOCKER_IMAGE_NAME) $(DOCKER_IMAGE_NAME):$(DOCKER_TAG)

.PHONY: stop
stop:
	@echo "Stopping Docker container..."
	docker stop $(DOCKER_IMAGE_NAME) || true

.PHONY: clean
clean:
	@echo "Cleaning Docker containers and images..."
	docker rm $(DOCKER_IMAGE_NAME) || true
	docker rmi $(DOCKER_IMAGE_NAME):$(DOCKER_TAG) || true

.PHONY: logs
logs:
	@echo "Showing Docker container logs..."
	docker logs $(DOCKER_IMAGE_NAME)

.PHONY: shell
shell:
	@echo "Opening shell in Docker container..."
	docker exec -it $(DOCKER_IMAGE_NAME) /bin/bash

.PHONY: docker-dev
docker-dev:
	@echo "Starting development environment with Docker Compose..."
	docker-compose up -d

# Deployment (Kamal)
.PHONY: deploy
deploy:
	@echo "Deploying with Kamal..."
	kamal deploy

.PHONY: deploy-production
deploy-production:
	@echo "Production Deployment"
	@echo "===================="
	@./scripts/populate-production-secrets.rb
	@echo ""
	@kamal deploy -d production

.PHONY: deploy-production-secrets
deploy-production-secrets:
	@echo "Fetching production secrets from AWS..."
	@./scripts/populate-production-secrets.rb

.PHONY: deploy-setup
deploy-setup:
	@echo "Setting up deployment with Kamal..."
	kamal setup

# Maintenance
.PHONY: clean-logs
clean-logs:
	@echo "Cleaning log files..."
	rm -f log/*.log

.PHONY: clean-tmp
clean-tmp:
	@echo "Cleaning temporary files..."
	rm -rf tmp/cache/*
	rm -rf tmp/pids/*

.PHONY: clean-all
clean-all: clean-logs clean-tmp assets-clean
	@echo "Cleaning all temporary files and assets..."

# Help
.PHONY: help
help:
	@echo "VNDG-ME Rails Application Makefile"
	@echo ""
	@echo "Setup and Installation:"
	@echo "  setup              - Complete application setup (install + db:prepare + seed)"
	@echo "  install            - Install Ruby dependencies"
	@echo ""
	@echo "Development:"
	@echo "  dev                - Start development server (using bin/dev)"
	@echo "  server             - Start Rails server"
	@echo "  console            - Start Rails console"
	@echo "  routes             - Display application routes"
	@echo ""
	@echo "Database:"
	@echo "  db-create          - Create databases"
	@echo "  db-migrate         - Run database migrations"
	@echo "  db-rollback        - Rollback database migration"
	@echo "  db-seed            - Seed database"
	@echo "  db-reset           - Reset database"
	@echo "  db-drop            - Drop databases"
	@echo ""
	@echo "Testing:"
	@echo "  test               - Run RSpec tests"
	@echo "  test-fast          - Run RSpec tests in parallel"
	@echo "  test-coverage      - Run tests with coverage report"
	@echo ""
	@echo "Code Quality:"
	@echo "  lint               - Run RuboCop linter"
	@echo "  lint-fix           - Run RuboCop with auto-correct"
	@echo "  security           - Run security checks (Brakeman + Bundle Audit)"
	@echo ""
	@echo "Assets:"
	@echo "  assets-precompile  - Precompile assets for production"
	@echo "  assets-clean       - Clean compiled assets"
	@echo ""
	@echo "Docker:"
	@echo "  build              - Build Docker image"
	@echo "  run                - Run Docker container"
	@echo "  stop               - Stop Docker container"
	@echo "  clean              - Remove Docker container and image"
	@echo "  logs               - Show Docker container logs"
	@echo "  shell              - Open shell in Docker container"
	@echo "  docker-dev         - Start development with Docker Compose"
	@echo ""
	@echo "Deployment:"
	@echo "  deploy             - Deploy with Kamal"
	@echo "  deploy-setup       - Setup deployment with Kamal"
	@echo ""
	@echo "Maintenance:"
	@echo "  clean-logs         - Clean log files"
	@echo "  clean-tmp          - Clean temporary files"
	@echo "  clean-all          - Clean all temporary files and assets"