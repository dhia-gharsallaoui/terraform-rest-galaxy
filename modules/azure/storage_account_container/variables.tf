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

variable "container_name" {
  type        = string
  description = "The name of the blob container to create."
}

variable "public_access" {
  type        = string
  default     = "None"
  description = "The level of public access. Options: None, Blob, Container."

  validation {
    condition     = contains(["None", "Blob", "Container"], var.public_access)
    error_message = "public_access must be 'None', 'Blob', or 'Container'."
  }
}

variable "auth_ref" {
  type        = string
  default     = null
  description = "Reference to a named_auth entry in the provider for cross-tenant auth."
}
