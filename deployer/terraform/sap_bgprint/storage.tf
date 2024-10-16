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
}

# Import the existing storage container
resource "azurerm_storage_container" "container" {
    name                        = "printjobs"
    storage_account_name        = azurerm_storage_account.storage_account.name
    container_access_type       = "container"
    depends_on                  = [ azurerm_storage_account.storage_account ]
}

resource "azurerm_storage_table" "table" {
    name                        = "printjobstatus"
    storage_account_name        = azurerm_storage_account.storage_account.name
    depends_on                  = [ azurerm_storage_account.storage_account ]
}

# Import the existing storage queue
resource "azurerm_storage_queue" "queue" {
    name                        = "printjobs"
    storage_account_name        = azurerm_storage_account.storage_account.name
    depends_on                  = [ azurerm_storage_account.storage_account ]
}