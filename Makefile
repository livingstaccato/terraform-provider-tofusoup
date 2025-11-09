# Terraform Provider TofuSoup - Makefile
#
# NOTE: This Makefile follows terraform-provider-pyvider as the reference implementation.
# TODO: Establish formal Makefile template system in provide-foundry for consistency across all provider projects.

.PHONY: help
help: ## Show this help message
	@echo "Terraform Provider TofuSoup - Development Commands"
	@echo "=================================================="
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Quick Start:"
	@echo "  make dev            # Quick development setup and build"
	@echo "  make build          # Build the provider"
	@echo "  make test           # Run tests"
	@echo "  make docs           # Build documentation"

# Configuration
PROVIDER_NAME := terraform-provider-tofusoup
VERSION ?= 0.0.1108
SHELL := /bin/bash

# Platform detection
UNAME_S := $(shell uname -s | tr '[:upper:]' '[:lower:]')
UNAME_M := $(shell uname -m)

# Convert uname -m output to Go arch naming
ifeq ($(UNAME_M),x86_64)
    ARCH := amd64
else ifeq ($(UNAME_M),arm64)
    ARCH := arm64
else ifeq ($(UNAME_M),aarch64)
    ARCH := arm64
else
    ARCH := $(UNAME_M)
endif
CURRENT_PLATFORM := $(UNAME_S)_$(ARCH)

# Paths
VENV := .venv
INSTALL_DIR := $(HOME)/.terraform.d/plugins/local/providers/tofusoup/$(VERSION)/$(CURRENT_PLATFORM)
PSP_FILE := dist/$(PROVIDER_NAME).psp
VERSIONED_BINARY := $(INSTALL_DIR)/$(PROVIDER_NAME)

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# ==============================================================================
# 🚀 Quick Commands
# ==============================================================================

.PHONY: all
all: clean venv deps docs build test ## Run full development cycle

.PHONY: dev
dev: venv deps build install ## Quick development setup and build

# ==============================================================================
# 🔧 Setup & Environment
# ==============================================================================

.PHONY: venv
venv: ## Create virtual environment
	@if [ ! -d "$(VENV)" ]; then \
		echo "$(BLUE)🔧 Creating virtual environment...$(NC)"; \
		uv venv $(VENV); \
		echo "$(GREEN)✅ Virtual environment created$(NC)"; \
	else \
		echo "$(GREEN)✅ Virtual environment already exists$(NC)"; \
	fi

.PHONY: deps
deps: venv ## Install dependencies with uv
	@echo "$(BLUE)📦 Installing dependencies...$(NC)"
	@. $(VENV)/bin/activate && uv sync --all-groups
	@echo "$(GREEN)✅ Dependencies installed$(NC)"

# ==============================================================================
# 🏗️ Build & Package
# ==============================================================================

.PHONY: keys
keys: ## Generate signing keys if missing
	@if [ ! -f keys/provider-private.key ]; then \
		echo "$(BLUE)🔑 Generating signing keys...$(NC)"; \
		mkdir -p keys; \
		. $(VENV)/bin/activate && \
		flavor keygen --out-dir keys; \
		echo "$(GREEN)✅ Keys generated$(NC)"; \
	else \
		echo "$(GREEN)✅ Signing keys already exist$(NC)"; \
	fi

.PHONY: build
build: venv deps keys ## Build provider binary with FlavorPack
	@echo "$(BLUE)🏗️ Building provider version $(VERSION) for $(CURRENT_PLATFORM)...$(NC)"
	@. $(VENV)/bin/activate && \
		flavor pack && \
		echo "$(GREEN)✅ Provider built: $(PSP_FILE)$(NC)" && \
		mkdir -p $(INSTALL_DIR) && \
		cp $(PSP_FILE) $(VERSIONED_BINARY) && \
		chmod +x $(VERSIONED_BINARY) && \
		echo "$(GREEN)✅ Versioned binary created: $(VERSIONED_BINARY)$(NC)" && \
		ls -lh $(PSP_FILE) $(VERSIONED_BINARY)

.PHONY: install
install: build ## Install provider to local Terraform plugins directory
	@echo "$(GREEN)✅ Provider installed to: $(INSTALL_DIR)$(NC)"
	@ls -lh $(VERSIONED_BINARY)

plating: venv
	@echo "Generating documentation with Plating..."
	@. $(VENV)/bin/activate && \
		plating plate

docs-setup: venv
	@echo "Extracting theme assets from provide-foundry..."
	@. $(VENV)/bin/activate && python -c "from provide.foundry.config import extract_base_mkdocs; from pathlib import Path; extract_base_mkdocs(Path('.'))"

docs-build: docs-setup plating
	@echo "Building documentation with MkDocs..."
	@. $(VENV)/bin/activate && mkdocs build

docs: docs-build

docs-serve: docs-setup docs
	@echo "Serving documentation at http://localhost:8000"
	@. $(VENV)/bin/activate && \
		mkdocs serve

clean:
	@echo "Cleaning build artifacts..."
	@rm -rf dist/
	@rm -rf build/
	@rm -rf *.egg-info
	@rm -rf .pytest_cache
	@rm -rf .mypy_cache
	@rm -rf .ruff_cache
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@echo "Clean complete"
