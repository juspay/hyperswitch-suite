# ============================================================================
# Hyperswitch Suite — Development Tasks
# ============================================================================
# Usage: just <recipe>
# Install just: https://github.com/casey/just

# Default recipe — show available commands
default:
	@just --list

# ============================================================================
# Terraform Documentation
# ============================================================================

# Generate terraform-docs for all module layers (base, composition, application-resources)
gen-docs:
	@echo "Generating terraform-docs for all module layers..."
	@for dir in $$(find terraform/aws/modules/base terraform/aws/modules/composition terraform/aws/modules/application-resources -name "main.tf" -exec dirname {} \; | sort); do \
		echo "  $$dir"; \
		terraform-docs --config terraform/aws/modules/.terraform-docs.yml "$$dir" >/dev/null 2>&1 || true; \
		done
	@echo "Done."

# Generate terraform-docs for a specific module directory
gen-docs-module MODULE_DIR:
	@echo "Generating terraform-docs for {{MODULE_DIR}}..."
	@terraform-docs --config terraform/aws/modules/.terraform-docs.yml {{MODULE_DIR}}

# Check if terraform-docs is installed
check-docs:
	@which terraform-docs >/dev/null 2>&1 && echo "terraform-docs: $$(terraform-docs --version)" || echo "terraform-docs: NOT INSTALLED (brew install terraform-docs)"

# ============================================================================
# Terraform / Terragrunt Cache Cleanup
# ============================================================================

# Clean all terraform and terragrunt cache
clean-cache: clean-terragrunt-cache clean-terraform-dirs clean-terraform-lock

# Clean .terragrunt-cache directories
clean-terragrunt-cache:
	@echo "Removing .terragrunt-cache directories..."
	@find . -name ".terragrunt-cache" -type d -prune -exec rm -rf {} +
	@echo "Done."

# Clean .terraform directories
clean-terraform-dirs:
	@echo "Removing .terraform directories..."
	@find . -name ".terraform" -type d -prune -exec rm -rf {} +
	@echo "Done."

# Clean .terraform.lock.hcl files
clean-terraform-lock:
	@echo "Removing .terraform.lock.hcl files..."
	@find . -name ".terraform.lock.hcl" -type f -delete
	@echo "Done."

# List all cache directories and files (dry run)
list-cache:
	@echo "=== .terragrunt-cache directories ==="
	@find . -name ".terragrunt-cache" -type d 2>/dev/null | head -20 || echo "None found"
	@echo ""
	@echo "=== .terraform directories ==="
	@find . -name ".terraform" -type d 2>/dev/null | head -20 || echo "None found"
	@echo ""
	@echo "=== .terraform.lock.hcl files ==="
	@find . -name ".terraform.lock.hcl" -type f 2>/dev/null | head -20 || echo "None found"

# ============================================================================
# Aliases
# ============================================================================

# Abbreviated alias for clean-cache
alias cc := clean-cache

# Abbreviated alias for list-cache
alias lc := list-cache

# Abbreviated alias for clean-terragrunt-cache
alias ctc := clean-terragrunt-cache

# Abbreviated alias for clean-terraform-dirs
alias ctd := clean-terraform-dirs

# Abbreviated alias for clean-terraform-lock
alias ctl := clean-terraform-lock

# Abbreviated alias for gen-docs
alias gd := gen-docs
