resource "random_string" "random" {
    length           = 8
    special          = false
}

# Import the existing storage account
resource "azurerm_storage_account" "storage_account" {
    name                        = format("%s%s%s", lower(var.environment), lower(var.location), lower(random_string.random.result))
    resource_group_name         = azurerm_resource_group.rg.name
    location                    = azurerm_resource_group.rg.location
    account_tier                = "Standard"
    account_replication_type    = "LRS"
    shared_access_key_enabled   = false
    depends_on                  = [ azurerm_subnet.subnet ]
    public_network_access_enabled = false
}

# Import the existing storage container
resource "azurerm_storage_container" "container" {
    name                        = var.storage_container_name
    storage_account_name        = azurerm_storage_account.storage_account.name
    container_access_type       = "container"
    depends_on                  = [ azurerm_storage_account.storage_account, azurerm_role_assignment.blob ]
}

resource "azurerm_storage_table" "table" {
    name                        = var.storage_table_name
    storage_account_name        = azurerm_storage_account.storage_account.name
    depends_on                  = [azurerm_storage_account.storage_account, azurerm_role_assignment.table]
}

# Import the existing storage queue
resource "azurerm_storage_queue" "queue" {
    name                        = var.storage_queue_name
    storage_account_name        = azurerm_storage_account.storage_account.name
    depends_on                  = [azurerm_storage_account.storage_account, azurerm_role_assignment.queue]
}