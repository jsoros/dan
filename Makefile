.PHONY: help init plan apply destroy validate fmt clean

# Default target
help:
	@echo "Available targets:"
	@echo "  init      - Initialize Terraform"
	@echo "  validate  - Validate Terraform configuration"
	@echo "  fmt       - Format Terraform files"
	@echo "  plan      - Plan infrastructure changes"
	@echo "  apply     - Apply infrastructure changes"
	@echo "  destroy   - Destroy infrastructure"
	@echo "  clean     - Clean temporary files"

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
