# kubernetes cluster

resource "azurerm_kubernetes_cluster" "aks_cluster" {
    count                   = var.sap_up_platform == "aks" ? 1 : 0
    name                    = format("%s-%s-akscluster", lower(var.environment), lower(var.location))
    location                = azurerm_resource_group.rg.location
    resource_group_name     = azurerm_resource_group.rg.name
    dns_prefix              = format("%s-%s-aks", lower(var.environment), lower(var.location))
    private_cluster_enabled = true
    oidc_issuer_enabled     = true
    workload_identity_enabled = true

    default_node_pool {
        name                = "default"
        node_count          = 2
        vm_size             = "Standard_DS3_v2"
        vnet_subnet_id      = azurerm_subnet.subnet.id
    }

    identity {
        identity_ids        = [azurerm_user_assigned_identity.msi.id]
        type                = "UserAssigned"
    }

    network_profile {
        network_plugin      = "azure"
        network_policy      = "calico"
        service_cidr        = var.aks_service_cidr
        dns_service_ip      = var.aks_dns_service_ip
        load_balancer_sku   = "standard"
        outbound_type       = "managedNATGateway"
    }

    kubelet_identity {
        user_assigned_identity_id = azurerm_user_assigned_identity.msi.id
        client_id            = azurerm_user_assigned_identity.msi.client_id
        object_id            = azurerm_user_assigned_identity.msi.principal_id
    }

    service_mesh_profile {
        mode                 = "Istio"
        external_ingress_gateway_enabled = true
    }
}