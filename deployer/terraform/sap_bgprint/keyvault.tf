# Import the existing key vault
resource "azurerm_key_vault" "kv" {
    name                        = format("%s%s%s", lower(var.environment), lower(var.location), lower("kv"))
    resource_group_name         = azurerm_resource_group.rg.name
    location                    = azurerm_resource_group.rg.location
    enabled_for_disk_encryption = true
    purge_protection_enabled    = false
    tenant_id                   = azurerm_user_assigned_identity.msi.tenant_id
    sku_name                    = "standard"
    access_policy {
        tenant_id               = azurerm_user_assigned_identity.msi.tenant_id
        object_id               = azurerm_user_assigned_identity.msi.principal_id
        secret_permissions      = [
            "Get",
            "List",
            "Set",
            "Delete",
            "Purge"
        ]
    }
}
