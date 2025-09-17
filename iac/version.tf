terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.44.0"
    }
    azuread = {
      source = "hashicorp/azuread"
      version = "3.5.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "tdc-sp-2025-tfstate"
    storage_account_name = "stgtdcsp2025tfstate"
    container_name       = "tfstate"
    use_oidc = true
  }
}

provider "azurerm" {
  use_oidc = true
  features {}
}

provider "azuread" {
}

data "azurerm_client_config" "current" {}