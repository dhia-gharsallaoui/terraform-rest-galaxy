# terraform-rest-galaxy
#
# Multi-purpose Terraform root module for Azure, Entra ID, GitHub, and Kubernetes.
# Infrastructure is declared in YAML configuration files and resolved at plan time.
#
# Entry points:
#   - azure_provider.tf   — REST provider configuration
#   - azure_layers.tf     — YAML config loading and layer context accumulation
#   - azure_versions.tf   — required_providers and terraform version constraints
#   - azure_variables.tf  — input variables
#   - azure_outputs.tf    — output values
#
# Usage:
#   terraform init -backend=false
#   terraform plan -var="config_file=configurations/storage_account_minimum.yaml"
