SHELL := /bin/bash

# Default target
.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help message
	@printf 'Usage: make [target]\n\n'
	@printf "\033[1;97mAvailable targets:\033[0m"
	@awk 'BEGIN {FS = ":.*?## "} /^\.PHONY:/ {printf "\n"} /^[a-zA-Z_-]+:.*?## / {printf "  \033[1;94m%-16s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: install upgrade
install: ## Install all dependencies and pre-commit hooks
	@printf "📦 Installing all dependencies...\n\n"
	uv sync --all-extras --frozen
	uv run prek install --overwrite
upgrade: ## Upgrade all dependencies and pre-commit hooks
	@printf "🔁 Upgrading dependencies...\n\n"
	uv sync --all-extras --upgrade --compile-bytecode
	uv run prek autoupdate

.PHONY: lint lint-diff lint-all
lint: ## Lint and format code for changed files
	@printf "🧭 Running pre-commit hooks for changed files...\n\n"
	git add --all && uv run --frozen --extra devel prek run
lint-diff: ## Run pre-commit hooks for files changed in this diff
	@printf "🧭 Running pre-commit hooks for files changed in this diff...\n\n"
	@if [ "$$(git branch --show-current)" = "main" ]; then \
		printf "⚠️  You are on the main branch. Skipping lint-diff.\n"; \
	else \
		uv run --frozen --extra devel prek run --from-ref main --to-ref HEAD; \
	fi
lint-all: ## Lint and format all files using pre-commit hooks
	@printf "🧭 Running pre-commit hooks...\n"
	uv run --frozen --extra devel prek run --all-files

.PHONY: install-git-aliases install-git-aliases-force
install-git-aliases: ## install aliases-git module
	@printf "📦 Installing aliases-git module...\n\n"
	@./module_manage.ps1 aliases-git -CleanUp
install-git-aliases-force: ## install aliases-git module (force)
	@printf "📦 Installing aliases-git module (force)...\n\n"
	@./module_manage.ps1 aliases-git -CleanUp -Force

.PHONY: install-kubectl-aliases install-kubectl-aliases-force
install-kubectl-aliases: ## install aliases-kubectl module
	@printf "📦 Installing aliases-kubectl module...\n\n"
	@./module_manage.ps1 aliases-kubectl -CleanUp
install-kubectl-aliases-force: ## install aliases-kubectl module (force)
	@printf "📦 Installing aliases-kubectl module (force)...\n\n"
	@./module_manage.ps1 aliases-kubectl -CleanUp -Force

.PHONY: install-az-do install-az-do-force
install-az-do: ## Install do-az module
	@printf "📦 Installing do-az module...\n\n"
	@./module_manage.ps1 do-az -CleanUp
install-az-do-force: ## Install do-az module (force)
	@printf "📦 Installing do-az module (force)...\n\n"
	@./module_manage.ps1 do-az -CleanUp -Force

.PHONY: install-common-do install-common-do-force
install-common-do: ## Install do-common module
	@printf "📦 Installing do-common module...\n\n"
	@sudo pwsh -c './module_manage.ps1 do-common -CleanUp'
install-common-do-force: ## Install do-common module (force)
	@printf "📦 Installing do-common module (force)...\n\n"
	@sudo pwsh -c './module_manage.ps1 do-common -CleanUp -Force'

.PHONY: install-linux-do install-linux-do-force
install-linux-do: ## Install do-linux module
	@printf "📦 Installing do-linux module...\n\n"
	@./module_manage.ps1 do-linux -CleanUp
install-linux-do-force: ## Install do-linux module (force)
	@printf "📦 Installing do-linux module (force)...\n\n"
	@./module_manage.ps1 do-linux -CleanUp -Force

.PHONY: test test-coverage
bootstrap-module: ## Run all tests
	@printf "🧪 Running tests...\n\n"
	@./module_manage.ps1 -Create

.PHONY: delete-module
delete-module: ## Lint and format code for changed files
	@printf "🧭 Running pre-commit hooks for changed files...\n\n"
	@./module_manage.ps1 -Delete

.PHONY: mkdocs-build mkdocs-serve
mkdocs-build: ## Build the mkdocs documentation (runs tests as part of the build)
	@printf "📚 Building mkdocs documentation...\n\n"
	uv run --frozen mkdocs build --strict
mkdocs-serve: ## Serve mkdocs documentation
	@printf "🚀 Serving mkdocs documentation...\n\n"
	uv run --frozen mkdocs serve --livereload
mkdocs-pages: ## Push mkdocs documentation to GitHub Pages
	@printf "🚀 Pushing mkdocs documentation to GitHub Pages...\n\n"
	uv run --frozen mkdocs gh-deploy

.PHONY: clean
clean: ## Clean build artifacts
	@printf "🧹 Cleaning build artifacts...\n\n"
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@printf "\n✅ Cleanup complete\n"
