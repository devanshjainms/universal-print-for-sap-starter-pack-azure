# Import the existing resource group
resource "azurerm_resource_group" "rg" {
    name                        = format("%s-%s-RG", upper(var.environment), upper(var.location))
    location                    = var.location
    tags                        = var.resource_group_tags
}

# create msi for the function app to access the key vault and storage account
resource "azurerm_user_assigned_identity" "msi" {
    name                        = format("%s%s%s", lower(var.environment), lower(var.location), lower("msi"))
    location                    = azurerm_resource_group.rg.location 
    resource_group_name         = azurerm_resource_group.rg.name
}

#assign roles to the msi to access the key vault and storage account
resource "azurerm_role_assignment" "keyvault" {
    scope                   = azurerm_key_vault.kv.id
    principal_id            = azurerm_user_assigned_identity.msi.principal_id
    role_definition_name    = "Key Vault Secrets Officer"
}

resource "azurerm_role_assignment" "queue" {
    scope                   = azurerm_storage_account.storage_account.id
    principal_id            = azurerm_user_assigned_identity.msi.principal_id
    role_definition_name    = "Storage Queue Data Contributor"
}

resource "azurerm_role_assignment" "blob" {
    scope                   = azurerm_storage_account.storage_account.id
    principal_id            = azurerm_user_assigned_identity.msi.principal_id
    role_definition_name    = "Storage Blob Data Contributor"
}

resource "azurerm_role_assignment" "table" {
    scope                   = azurerm_storage_account.storage_account.id
    principal_id            = azurerm_user_assigned_identity.msi.principal_id
    role_definition_name    = "Storage Table Data Contributor"
}

resource "azurerm_role_assignment" "acr" {
    scope                   = "/subscriptions/${var.subscription_id}/resourceGroups/${var.control_plane_rg}"
    principal_id            = azurerm_user_assigned_identity.msi.principal_id
    role_definition_name    = "AcrPull"
}

resource "azurerm_role_assignment" "network" {
    count                   = var.sap_up_platform == "aks" ? 1 : 0
    scope                   = azurerm_resource_group.rg.id
    principal_id            = azurerm_user_assigned_identity.msi.principal_id
    role_definition_name    = "Network Contributor"
}

resource "azurerm_role_assignment" "kubelet_identity_operator" {
    scope                   = azurerm_user_assigned_identity.msi.id
    count                   = var.sap_up_platform == "aks" ? 1 : 0
    principal_id            = azurerm_user_assigned_identity.msi.principal_id
    role_definition_name    = "Managed Identity Operator"
}

resource "azurerm_federated_identity_credential" "keyvault_fic" {
    name                    = "acr-fic"
    count                   = var.sap_up_platform == "aks" ? 1 : 0
    resource_group_name     = azurerm_resource_group.rg.name
    audience                = ["api://AzureADTokenExchange"]
    issuer                  = azurerm_kubernetes_cluster.aks_cluster[0].kubelet_identity[0].client_id
    parent_id               = azurerm_user_assigned_identity.msi.id
    subject                 = "system:serviceaccount:default:bgprint-service-account"
}

# Azure AD Application Registration for the custom connector
resource "azuread_application_registration" "app" {
    display_name                = format("%s%s%s", upper(var.environment), "-BGPRINT-APP-", upper(random_string.random.result))
}

resource "azuread_application_api_access" "app_access" {
    application_id              = azuread_application_registration.app.id
    api_client_id               = "00000003-0000-0000-c000-000000000000"
    scope_ids                   = [
        "ed11134d-2f3f-440d-a2e1-411efada2502",
        "5fa075e9-b951-4165-947b-c63396ff0a37",
        "21f0d9c0-9f13-48b3-94e0-b6b231c7d320"
    ]
}

resource "azuread_application_redirect_uris" "redirect_uri" {
    application_id = azuread_application_registration.app.id
    type = "Web"
    redirect_uris = [
        jsondecode(azapi_resource.custom_connector.output).properties.connectionParameters.token.oAuthSettings.redirectUrl,
        "https://global.consent.azure-apim.net/redirect"
    ]
}

resource "azuread_application_password" "password" {
    application_id = azuread_application_registration.app.id
}

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

resource "azurerm_container_registry" "acr" {
    name                = "backendprintregistry"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    sku                 = "Premium"
}