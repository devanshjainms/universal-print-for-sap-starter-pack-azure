# Ensure the script is executed in PowerShell
if ($PSVersionTable.PSVersion.Major -lt 5) {
  Write-Host "This script requires PowerShell 5.0 or higher." -ForegroundColor Red
  exit
}

# Set environment variables
$envVars = @{
  WORKLOAD_ENVIRONMENT_CODE         = $Env:WORKLOAD_ENVIRONMENT_CODE
  ENTRA_ID_TENANT_ID                = $Env:ENTRA_ID_TENANT_ID
  AZURE_SUBSCRIPTION_ID             = $Env:AZURE_SUBSCRIPTION_ID
  CONTROL_PLANE_RESOURCE_GROUP_NAME = "$($Env:CONTROL_PLANE_ENVIRONMENT_CODE)-RG"
  STORAGE_ACCOUNT_NAME              = "$($Env:CONTROL_PLANE_ENVIRONMENT_CODE.ToLower())tstatebgprinting"
  ACR_NAME                          = $Env:CONTAINER_REGISTRY_NAME
  CONTAINER_NAME                    = "tfstate"
  ENABLE_LOGGING_ON_PLATFORM        = $Env:ENABLE_LOGGING_ON_PLATFORM
  MSI_CLIENT_ID                     = $Env:MSI_CLIENT_ID
  PLATFORM                          = "aks" #AKS of FUNCTIONAPP
}

# List of required environment variables
$requiredVariables = @(
  "WORKLOAD_ENVIRONMENT_CODE",
  "ENTRA_ID_TENANT_ID",
  "AZURE_SUBSCRIPTION_ID",
  "CONTROL_PLANE_RESOURCE_GROUP_NAME",
  "STORAGE_ACCOUNT_NAME",
  "CONTAINER_NAME",
  "ACR_NAME",
  "ENABLE_LOGGING_ON_PLATFORM"
)

# Check if required environment variables are set
foreach ($var in $requiredVariables) {
  if ([string]::IsNullOrEmpty($envVars[$var])) {
    Write-Host "$var is null or empty!" -ForegroundColor Red
    exit 1
  }
}

# Azure login
# if ([string]::IsNullOrEmpty($envVars.ENTRA_ID_TENANT_ID)) {
#   az login --output none --only-show-errors
# }
# else {
#   az login --output none --tenant $envVars.ENTRA_ID_TENANT_ID --only-show-errors
# }

# Set Azure CLI configuration
az config set extension.use_dynamic_install=yes_without_prompt --only-show-errors

# Set Azure subscription
if ([string]::IsNullOrEmpty($envVars.AZURE_SUBSCRIPTION_ID)) {
  Write-Host "AZURE_SUBSCRIPTION_ID is not set!" -ForegroundColor Red
  $envVars.AZURE_SUBSCRIPTION_ID = Read-Host "Please enter a subscription ID"
}
az account set --subscription $envVars.AZURE_SUBSCRIPTION_ID

# Set environment variables for Terraform
$terraformVars = @{
  TF_VAR_tenant_id                  = $envVars.ENTRA_ID_TENANT_ID
  TF_VAR_subscription_id            = $envVars.AZURE_SUBSCRIPTION_ID
  TF_VAR_client_id                  = $envVars.MSI_CLIENT_ID
  TF_VAR_location                   = $Env:LOCATION
  TF_VAR_environment                = $envVars.WORKLOAD_ENVIRONMENT_CODE
  TF_VAR_virtual_network_id         = $Env:SAP_VIRTUAL_NETWORK_ID
  TF_VAR_subnet_address_prefixes    = $Env:BGPRINT_SUBNET_ADDRESS_PREFIX
  TF_VAR_container_registry_url     = "$envVars.ACR_NAME.azurecr.io"
  TF_VAR_container_image_name       = "bgprinting"
  TF_VAR_control_plane_rg           = $envVars.CONTROL_PLANE_RESOURCE_GROUP_NAME
  TF_VAR_enable_logging_on_platform = $envVars.ENABLE_LOGGING_ON_PLATFORM
  TF_VAR_sap_up_platform            = $envVars.PLATFORM
}

foreach ($key in $terraformVars.Keys) {
  Set-Item -Path "Env:$key" -Value $terraformVars[$key]
}
# Change directory to the SAP print path
Set-Location -Path $Env:SAPPRINT_PATH

# Remove existing repository if it exists
if (Test-Path "universal-print-for-sap-starter-pack") {
  Remove-Item -Recurse -Force "universal-print-for-sap-starter-pack"
}

# Clone the git repository
Write-Host "######## Cloning the code repo ########" -ForegroundColor Green
git clone https://github.com/devanshjainms/universal-print-for-sap-starter-pack-azure.git
Set-Location -Path "./universal-print-for-sap-starter-pack-azure"
git checkout kube-test

# Create resource group
az group create --name $envVars.CONTROL_PLANE_RESOURCE_GROUP_NAME --location eastus --only-show-errors

# Create the Azure container registry and build the docker image
Write-Host "######## Build the docker image and push it to the ACR registry ########" -ForegroundColor Green
az acr create --name $envVars.ACR_NAME --resource-group $envVars.CONTROL_PLANE_RESOURCE_GROUP_NAME --sku Basic
Start-Sleep -Seconds 10 # Wait for the ACR to be created
az acr show --name $envVars.ACR_NAME --resource-group $envVars.CONTROL_PLANE_RESOURCE_GROUP_NAME
az acr login --name $envVars.ACR_NAME --resource-group $envVars.CONTROL_PLANE_RESOURCE_GROUP_NAME --expose-token
az acr build --registry $envVars.ACR_NAME --resource-group $envVars.CONTROL_PLANE_RESOURCE_GROUP_NAME --image bgprinting:latest --file ./backend-printing/Dockerfile ./backend-printing --no-logs

# Create storage account
Write-Host "######## Creating storage account to store the terraform state ########" -ForegroundColor Green
az storage account create --resource-group $envVars.CONTROL_PLANE_RESOURCE_GROUP_NAME --name $envVars.STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob --only-show-errors
az storage account update --resource-group $envVars.CONTROL_PLANE_RESOURCE_GROUP_NAME --name $envVars.STORAGE_ACCOUNT_NAME --https-only true --allow-blob-public-access false --only-show-errors
az storage container create --name $envVars.CONTAINER_NAME --account-name $envVars.STORAGE_ACCOUNT_NAME --only-show-errors

$terraform_key = "$($envVars.WORKLOAD_ENVIRONMENT_CODE).terraform.tfstate"
$terraform_directory = "./deployer/terraform"
Write-Host "Terraform directory: $terraform_directory"

# Check if the Terraform directory exists
if (-Not (Test-Path -Path $terraform_directory)) {
  Write-Error "Terraform directory does not exist: $terraform_directory"
  exit 1
}

# Initialize Terraform
Write-Host "######## Initializing Terraform ########" -ForegroundColor Green

# Retrieve environment variables
$storageAccountName = $envVars.STORAGE_ACCOUNT_NAME
$resourceGroupName = $envVars.CONTROL_PLANE_RESOURCE_GROUP_NAME
$containerName = $envVars.CONTAINER_NAME
$tenantId = $Env:ENTRA_ID_TENANT_ID
$clientId = $Env:MSI_CLIENT_ID
$subscriptionId = $Env:AZURE_SUBSCRIPTION_ID

if (-not $storageAccountName -or -not $resourceGroupName -or -not $containerName -or -not $tenantId -or -not $clientId -or -not $subscriptionId) {
  Write-Error "One or more required environment variables are not set."
  exit 1
}

try {
  terraform -chdir="$terraform_directory" init -reconfigure -upgrade `
    -backend-config="key=$terraform_key" `
    -backend-config="storage_account_name=$storageAccountName" `
    -backend-config="resource_group_name=$resourceGroupName" `
    -backend-config="container_name=$containerName" `
    -backend-config="tenant_id=$tenantId" `
    -backend-config="client_id=$clientId" `
    -backend-config="subscription_id=$subscriptionId"
}
catch {
  Write-Error "Terraform initialization failed"
  exit 1
}

# Refresh Terraform
Write-Host "######## Refreshing Terraform ########" -ForegroundColor Green
try {
  terraform -chdir="$terraform_directory" refresh
}
catch {
  Write-Error "Terraform refresh failed"
  exit 1
}

# Plan Terraform
Write-Host "######## Planning the Terraform ########" -ForegroundColor Green
try {
  terraform -chdir="$terraform_directory" plan -compact-warnings -json -no-color -parallelism=5
}
catch {
  Write-Error "Terraform plan failed"
  exit 1
}

# Apply Terraform
Write-Host "######## Applying the Terraform ########" -ForegroundColor Green
try {
  terraform -chdir="$terraform_directory" apply -auto-approve -compact-warnings -json -no-color -parallelism=5
}
catch {
  Write-Error "Terraform apply failed"
  exit 1
}

# If the platform type is aks, then deploy the service on aks platform
if ($envVars.PLATFORM -eq "aks") {    
  Write-Host "######## Deploying the service on aks platform ########" -ForegroundColor Green
  
  # Function to get Terraform outputs as a hashtable
  function Get-TerraformOutputs {
    $terraformOutputs = terraform output -json | ConvertFrom-Json
    $secrets = @{}
    foreach ($key in $terraformOutputs.PSObject.Properties.Name) {
      $secrets[$key] = $terraformOutputs.$key.value
    }
    return $secrets
  }

  # Get Terraform outputs
  $secrets = Get-TerraformOutputs

  # Check if required secrets are available
  if (-Not $secrets.ContainsKey("resource_group_name") -or -Not $secrets.ContainsKey("aks_cluster_name")) {
    Write-Error "Required Terraform outputs are missing: resource_group_name or aks_cluster_name"
    exit 1
  }

  # Extract resource group and cluster name from secrets
  $resourceGroup = $secrets["resource_group_name"]
  $clusterName = $secrets["aks_cluster_name"]

  # Define other parameters
  $acrRegistry = "$($envVars.ACR_NAME).azurecr.io"  # Construct the ACR registry URL
  $imageName = "bgprinting:latest"

  # Call the script with parameters
  & .\kubernetes_service_deploy.ps1 -resourceGroup $resourceGroup -clusterName $clusterName -secrets $secrets -acrRegistry $acrRegistry -imageName $imageName
}