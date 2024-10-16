#create a subnet in the virtual network
resource "azurerm_subnet" "subnet" {
    name                        = format("bgprint-subnet")
    resource_group_name         = split("/", var.virtual_network_id)[4]
    virtual_network_name        = split("/", var.virtual_network_id)[8]
    address_prefixes            = [var.subnet_address_prefixes]
}

resource "azurerm_route_table" "aks_route_table" {
    name                        = "aks-route-table"
    location                    = azurerm_resource_group.rg.location
    resource_group_name         = azurerm_resource_group.rg.name
}

resource "azurerm_subnet_route_table_association" "aks_subnet_route_table_association" {
    subnet_id                   = azurerm_subnet.subnet.id
    route_table_id              = azurerm_route_table.aks_route_table.id
}

# Create private endpoint for storage account
resource "azurerm_private_endpoint" "storage_pe" {
    name                        = "storage-private-endpoint"
    location                    = azurerm_resource_group.rg.location
    resource_group_name         = azurerm_resource_group.rg.name
    subnet_id                   = azurerm_subnet.subnet.id

    private_service_connection {
        name                    = "storage-psc"
        private_connection_resource_id = azurerm_storage_account.storage_account.id
        is_manual_connection    = false
        subresource_names       = ["blob", "queue", "table"]
    }
}

# Create private endpoint for key vault
resource "azurerm_private_endpoint" "keyvault_pe" {
    name                        = "keyvault-private-endpoint"
    location                    = azurerm_resource_group.rg.location
    resource_group_name         = azurerm_resource_group.rg.name
    subnet_id                   = azurerm_subnet.subnet.id

    private_service_connection {
        name                           = "keyvault-psc"
        private_connection_resource_id = azurerm_key_vault.kv.id
        is_manual_connection           = false
        subresource_names              = ["vault"]
    }
}

# Add private DNS zone for storage account
resource "azurerm_private_dns_zone" "storage_dns" {
    name                        = "privatelink.blob.core.windows.net"
    resource_group_name         = azurerm_resource_group.rg.name
}

# Add private DNS zone for key vault
resource "azurerm_private_dns_zone" "keyvault_dns" {
    name                        = "privatelink.vaultcore.azure.net"
    resource_group_name         = azurerm_resource_group.rg.name
}

# Link private DNS zone to virtual network for storage account
resource "azurerm_private_dns_zone_virtual_network_link" "storage_dns_link" {
    name                        = "storage-dns-link"
    resource_group_name         = azurerm_resource_group.rg.name
    private_dns_zone_name       = azurerm_private_dns_zone.storage_dns.name
    virtual_network_id          = var.virtual_network_id
}

# Link private DNS zone to virtual network for key vault
resource "azurerm_private_dns_zone_virtual_network_link" "keyvault_dns_link" {
    name                        = "keyvault-dns-link"
    resource_group_name         = azurerm_resource_group.rg.name
    private_dns_zone_name       = azurerm_private_dns_zone.keyvault_dns.name
    virtual_network_id          = var.virtual_network_id
}