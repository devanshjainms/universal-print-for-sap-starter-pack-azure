#create a subnet in the virtual network
resource "azurerm_subnet" "subnet" {
    name                        = format("bgprint-subnet")
    resource_group_name         = split("/", var.virtual_network_id)[4]
    virtual_network_name        = split("/", var.virtual_network_id)[8]
    address_prefixes            = [var.subnet_address_prefixes]
}

# Define the route table
resource "azurerm_route_table" "route_table" {
    name                = "aks-route-table"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}

# Associate the route table with the subnet
resource "azurerm_subnet_route_table_association" "subnet_association" {
    subnet_id      = azurerm_subnet.subnet.id
    route_table_id = azurerm_route_table.route_table.id
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

resource "azurerm_private_dns_zone" "acr_dns" {
    name                        = "privatelink.azurecr.io"
    resource_group_name         = azurerm_resource_group.rg.name
}

# Create private endpoint for storage account blob
resource "azurerm_private_endpoint" "storage_pe_blob" {
    name                        = "storage-private-endpoint-blob"
    location                    = azurerm_resource_group.rg.location
    resource_group_name         = azurerm_resource_group.rg.name
    subnet_id                   = azurerm_subnet.subnet.id

    private_service_connection {
        name                    = "storage-psc-blob"
        private_connection_resource_id = azurerm_storage_account.storage_account.id
        is_manual_connection    = false
        subresource_names       = ["blob"]
    }
}

# Create private endpoint for storage account queue
resource "azurerm_private_endpoint" "storage_pe_queue" {
    name                        = "storage-private-endpoint-queue"
    location                    = azurerm_resource_group.rg.location
    resource_group_name         = azurerm_resource_group.rg.name
    subnet_id                   = azurerm_subnet.subnet.id

    private_service_connection {
        name                    = "storage-psc-queue"
        private_connection_resource_id = azurerm_storage_account.storage_account.id
        is_manual_connection    = false
        subresource_names       = ["queue"]
    }
}

# Create private endpoint for storage account table
resource "azurerm_private_endpoint" "storage_pe_table" {
    name                        = "storage-private-endpoint-table"
    location                    = azurerm_resource_group.rg.location
    resource_group_name         = azurerm_resource_group.rg.name
    subnet_id                   = azurerm_subnet.subnet.id

    private_service_connection {
        name                    = "storage-psc-table"
        private_connection_resource_id = azurerm_storage_account.storage_account.id
        is_manual_connection    = false
        subresource_names       = ["table"]
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

#create private endpoint for acr
resource "azurerm_private_endpoint" "acr_pe" {
    name                        = "acr-private-endpoint"
    location                    = azurerm_resource_group.rg.location
    resource_group_name         = azurerm_resource_group.rg.name
    subnet_id                   = azurerm_subnet.subnet.id

    private_service_connection {
        name                           = "acr-psc"
        private_connection_resource_id = azurerm_container_registry.acr.id
        is_manual_connection           = false
        subresource_names              = ["registry"]
    }
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

# Link private DNS zone to virtual network for acr
resource "azurerm_private_dns_zone_virtual_network_link" "acr_dns_link" {
    name                        = "acr-dns-link"
    resource_group_name         = azurerm_resource_group.rg.name
    private_dns_zone_name       = azurerm_private_dns_zone.acr_dns.name
    virtual_network_id          = var.virtual_network_id
}