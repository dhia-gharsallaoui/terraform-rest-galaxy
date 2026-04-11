variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID."
}

variable "resource_group_name" {
  type        = string
  description = "The resource group containing the storage account."
}

variable "account_name" {
  type        = string
  description = "The storage account name."
}

variable "queue_name" {
  type        = string
  description = "The name of the queue."
  default     = "events-queue"
}

variable "metadata" {
  type        = map(string)
  description = "Custom metadata key-value pairs."
  default = {
    environment = "production"
    team        = "platform"
    purpose     = "event-processing"
  }
}

variable "tenant_id" {
  type        = string
  default     = null
  description = "Azure AD tenant ID. Required for OIDC auth."
}

variable "client_id" {
  type        = string
  default     = null
  description = "Service principal client ID. Required for OIDC auth."
}

variable "id_token" {
  type        = string
  sensitive   = true
  default     = null
  description = "GitHub Actions OIDC JWT token."
}

variable "access_token" {
  type        = string
  sensitive   = true
  default     = null
  description = "Pre-fetched Azure access token."
}
