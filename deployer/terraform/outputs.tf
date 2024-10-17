output "resource_group_name" {
    description = "The name of the resource group"
    value       = module.sap_bgprint.resource_group_name
}

output "key_vault_name" {
    description = "The name of the key vault"
    value       = module.sap_bgprint.key_vault_name
}

output "storage_account_name" {
    description = "The name of the storage account"
    value       = module.sap_bgprint.storage_account_name
}

output "storage_account_key" {
    description = "The storage account key"
    value       = module.sap_bgprint.storage_account_key
}

output "storage_queue_name" {
    description = "The name of the storage queue"
    value       = module.sap_bgprint.storage_queue_name
}

output "storage_container_name" {
    description = "The name of the storage container"
    value       = module.sap_bgprint.storage_container_name
}

output "storage_table_name" {
    description = "The name of the storage table"
    value       = module.sap_bgprint.storage_table_name
}

output "logic_app_url" {
    description = "The url of the logic app"
    value       = module.sap_bgprint.logic_app_url
}

output "msi_client_id" {
    description = "The client id of the managed identity"
    value       = module.sap_bgprint.msi_client_id
}

output "azure_tenant_id" {
    description = "The tenant id of the managed identity"
    value       = module.sap_bgprint.azure_tenant_id
}

output "aks_cluster_name" {
    description = "The name of the AKS cluster"
    value       = module.sap_bgprint.aks_cluster_name
}

output "acr_registry_url" {
    description = "The url of the ACR registry"
    value       = module.sap_bgprint.acr_registry_url
}