output "resource_group_name" {
    description = "The name of the resource group"
    value       = azurerm_resource_group.rg.name
}

output "key_vault_name" {
    description = "The name of the key vault"
    value       = azurerm_key_vault.kv.name
}

output "storage_account_name" {
    description = "The name of the storage account"
    value       = azurerm_storage_account.storage_account.name
}

output "storage_account_key" {
    description = "The storage account key"
    value       = azurerm_storage_account.storage_account.primary_access_key
}

output "storage_queue_name" {
    description = "The name of the storage queue"
    value       = azurerm_storage_queue.queue.name
}

output "storage_container_name" {
    description = "The name of the storage container"
    value       = azurerm_storage_container.container.name
}

output "storage_table_name" {
    description = "The name of the storage table"
    value       = azurerm_storage_table.table.name
}

output "logic_app_url" {
    description = "The url of the logic app"
    value       = azurerm_logic_app_trigger_http_request.logic_app_trigger.callback_url
}

output "msi_client_id" {
    description = "The client id of the managed identity"
    value       = azurerm_user_assigned_identity.msi.client_id
}

output "azure_tenant_id" {
    description = "The tenant id of the managed identity"
    value       = azurerm_user_assigned_identity.msi.tenant_id
}

output "aks_cluster_name" {
    description = "The name of the AKS cluster"
    value       = azurerm_kubernetes_cluster.aks.name
}