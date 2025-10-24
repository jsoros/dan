.PHONY: help init plan apply destroy validate fmt clean install lint lint-fix test test-watch test-coverage ci

# Default target
help:
	@echo "Available targets:"
	@echo ""
	@echo "Development:"
	@echo "  install      - Install npm dependencies"
	@echo "  lint         - Run ESLint on canary scripts"
	@echo "  lint-fix     - Run ESLint and fix issues automatically"
	@echo "  test         - Run Jest unit tests"
	@echo "  test-watch   - Run Jest in watch mode"
	@echo "  test-coverage - Run tests with coverage report"
	@echo "  ci           - Run linting and tests (CI pipeline)"
	@echo ""
	@echo "Terraform:"
	@echo "  init      - Initialize Terraform"
	@echo "  validate  - Validate Terraform configuration"
	@echo "  fmt       - Format Terraform files"
	@echo "  plan      - Plan infrastructure changes"
	@echo "  apply     - Apply infrastructure changes"
	@echo "  destroy   - Destroy infrastructure"
	@echo ""
	@echo "Cleanup:"
	@echo "  clean     - Clean temporary files"

# Install npm dependencies
install:
	@echo "Installing npm dependencies..."
	npm install

# Run ESLint
lint:
	@echo "Running ESLint..."
	npm run lint

# Run ESLint with auto-fix
lint-fix:
	@echo "Running ESLint with auto-fix..."
	npm run lint:fix

# Run Jest tests
test:
	@echo "Running Jest tests..."
	npm test

# Run Jest in watch mode
test-watch:
	@echo "Running Jest in watch mode..."
	npm run test:watch

# Run tests with coverage
test-coverage:
	@echo "Running tests with coverage..."
	npm run test:coverage

# Run CI pipeline (lint + test)
ci: lint test
	@echo "✅ All CI checks passed!"

# Initialize Terraform
init:
	@echo "Initializing Terraform..."
	cd terraform && terraform init

# Validate Terraform configuration
validate:
	@echo "Validating Terraform configuration..."
	cd terraform && terraform validate

# Format Terraform files
fmt:
	@echo "Formatting Terraform files..."
	cd terraform && terraform fmt -recursive

# Plan infrastructure changes
plan:
	@echo "Planning infrastructure changes..."
	cd terraform && terraform plan

# Apply infrastructure changes
apply:
	@echo "Applying infrastructure changes..."
	cd terraform && terraform apply

# Destroy infrastructure
destroy:
	@echo "Destroying infrastructure..."
	cd terraform && terraform destroy

# Clean temporary files
clean:
	@echo "Cleaning temporary files..."
	rm -rf terraform/.terraform
	rm -rf terraform/canary-artifacts
	rm -f terraform/*.zip
	rm -f terraform/crash.log
	rm -f terraform/crash.*.log
