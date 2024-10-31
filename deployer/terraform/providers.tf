terraform {
    required_version = ">=0.12"

    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = "~>3.0"
        }
        azapi = {
            source  = "Azure/azapi"
            version = "1.15.0"
        }

        azuread = {
            source  = "hashicorp/azuread"
            version = "2.47.0"
        }
    }
}

provider "azurerm" {
    features {}
    storage_use_azuread = true
    tenant_id       = var.tenant_id
    subscription_id = var.subscription_id
}

provider "azapi" {
    tenant_id       = var.tenant_id
    subscription_id = var.subscription_id
}

provider "azuread" {
    tenant_id       = var.tenant_id
}