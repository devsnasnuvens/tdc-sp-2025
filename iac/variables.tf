variable "environment" {
  description = "The deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "application_name" {
  description = "The name of the application"
  type        = string
}

variable "app_service_plan_sku" {
  description = "The SKU for the App Service Plan"
  type        = string
  default     = "B1"
}

variable "location" {
  description = "The Azure region to deploy resources in"
  type        = string
}