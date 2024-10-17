# Define the input variables for the project

variable "environment" {
    description = "The environment for the resources"
    type        = string
}

variable "resource_group_name" {
    description = "The name of the resource group"
    type        = string
    default     = ""
}

variable "resource_group_tags" {
    description = "The tags for the resource group"
    type        = map
    default     = {}
}

variable "location" {
    description = "The location of the resources"
    type        = string
}

variable "subscription_id" {
    description = "The subscription id of the Azure account"
    type        = string
}

variable "tenant_id" {
    description = "The tenant id of the Azure account"
    type        = string
}

variable "client_id" {
    description = "The client id of the Azure account"
    type        = string
}

variable virtual_network_id {
    description = "The id of the virtual network"
    type        = string
}

variable "subnet_address_prefixes" {
    description = "The address prefixes for the subnet"
    type        = string
}

variable "microsoft_login_uri" {
    description = "The login uri for the Microsoft connector"
    type        = string
    default     = "https://login.microsoftonline.com"
}

variable "graph_resource_uri" {
    description = "The resource uri for the Microsoft Graph API"
    type        = string
    default     = "https://graph.microsoft.com"
}

variable "connector_description" {
    description = "The description for the custom connector"
    type        = string
    default     = "Microsoft Universal Print connector"
}

variable container_registry_url {
    description = "The url of the container registry"
    type        = string
}

variable "container_image_name" {
    description = "The name of the container image"
    type        = string
}

variable "control_plane_rg" {
    description = "The name of the control plane resource group"
    type        = string
}

variable "sap_up_platform" { 
    description = "The name of the platform on which the SAP UP solution is deployed. Supported values are 'aks' and 'functionapp'"
    type        = string
}

variable "aks_service_cidr" {
    description = "The service CIDR for the AKS cluster"
    type        = string
}

variable "aks_dns_service_ip" {
    description = "The DNS service IP for the AKS cluster"
    type        = string
}

variable "enable_logging_on_platform" {
    description = "Enable logging on the function app or AKS cluster"
    type        = bool
    default     = false
}