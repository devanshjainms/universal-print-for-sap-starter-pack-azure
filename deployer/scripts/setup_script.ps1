param (
    [string]$ControlPlaneEnvironmentCode = "CTRL",
    [string]$WorkloadEnvironmentCode = "TEST",
    [string]$Location = "",
    [string]$EntraIdTenantId = "",
    [string]$AzureSubscriptionId = "",
    [string]$SapVirtualNetworkId = "",
    [string]$BgprintSubnetAddressPrefix = "",
    [bool]$EnableLoggingOnPlatform = $false,
    [string]$ContainerRegistryName = "",
    [string]$MsiClientId = ""
)

Set-StrictMode -Version Latest

try {
    $Env:CONTROL_PLANE_ENVIRONMENT_CODE = $ControlPlaneEnvironmentCode
    $Env:WORKLOAD_ENVIRONMENT_CODE = $WorkloadEnvironmentCode
    $Env:LOCATION = $Location
    $Env:ENTRA_ID_TENANT_ID = $EntraIdTenantId
    $Env:AZURE_SUBSCRIPTION_ID = $AzureSubscriptionId
    $Env:SAP_VIRTUAL_NETWORK_ID = $SapVirtualNetworkId
    $Env:BGPRINT_SUBNET_ADDRESS_PREFIX = $BgprintSubnetAddressPrefix
    $Env:ENABLE_LOGGING_ON_PLATFORM = $EnableLoggingOnPlatform.ToString()
    $Env:CONTAINER_REGISTRY_NAME = $ContainerRegistryName
    $Env:MSI_CLIENT_ID = $MsiClientId

    $Env:SAPPRINT_PATH = Join-Path -Path $HOME -ChildPath "SAP-PRINT"
    if (-not (Test-Path -Path $Env:SAPPRINT_PATH)) {
        New-Item -Path $Env:SAPPRINT_PATH -Type Directory | Out-Null
    }

    Set-Location -Path $Env:SAPPRINT_PATH

    Get-ChildItem -Path $Env:SAPPRINT_PATH -Recurse | Remove-Item -Force -Recurse

    $scriptUrl = "https://raw.githubusercontent.com/Azure/universal-print-for-sap-starter-pack/main/deployer/scripts/install_backend_printing.ps1"
    $scriptPath = Join-Path -Path $Env:SAPPRINT_PATH -ChildPath "install_backend_printing.ps1"

    Invoke-RestMethod -Uri $scriptUrl -OutFile $scriptPath

    # Set the context to the specified subscription
    Set-AzContext -SubscriptionId $AzureSubscriptionId

    # Assign Contributor role to the MSI
    New-AzRoleAssignment -ObjectId $MsiClientId -RoleDefinitionName "Contributor" -Scope "/subscriptions/$AzureSubscriptionId"

    # Assign User Access Administrator role to the MSI
    New-AzRoleAssignment -ObjectId $MsiClientId -RoleDefinitionName "User Access Administrator" -Scope "/subscriptions/$AzureSubscriptionId"

    Invoke-Expression -Command $scriptPath

    Write-Output "Script executed successfully."
} catch {
    Write-Error "An error occurred: $_"
} finally {
    Set-StrictMode -Off
}