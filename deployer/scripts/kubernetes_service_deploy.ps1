# This PowerShell script deploys the backend printing service to the Azure Kubernetes Service (AKS) cluster.
# The k8s service configurations are defined in the ./backend-printing/k8s directory

param(
    [string]$resourceGroup = "myResourceGroup",
    [string]$clusterName = "myCluster",
    [hashtable]$secrets = @{ "mySecret" = "mySecretValue" },
    [string]$acrRegistry = "myAcrRegistry.azurecr.io",
    [string]$imageName = "myImageName"  # Added imageName parameter
)

function Get-AksCredentials {
    Write-Output "Getting AKS credentials..."
    az aks get-credentials --resource-group $resourceGroup --name $clusterName
}

function New-K8sSecret {
    $secretArgs = $secrets.GetEnumerator() | ForEach-Object { "--from-literal=$($_.Key)=$($_.Value)" } -join " "
    $createSecretCommand = "kubectl create secret generic my-secret $secretArgs"
    az aks command invoke --resource-group $resourceGroup --name $clusterName --command $createSecretCommand
}

function Invoke-K8sDeployment {
    $templateFile = "deployment.yaml.template"
    $deploymentFile = "deployment.yaml"
    $fullImageName = "$acrRegistry/$imageName"
    $imageEnv = @{ IMAGE_NAME = $fullImageName }
    (Get-Content $templateFile) -replace '\$\{IMAGE_NAME\}', $imageEnv.IMAGE_NAME | Set-Content $deploymentFile
    $applyDeploymentCommand = "kubectl apply -f deployment.yaml"
    az aks command invoke --resource-group $resourceGroup --name $clusterName --command $applyDeploymentCommand
}

function Invoke-K8sServices {
    $serviceFile = "service.yaml"
    $cronJobFile = "cronjob.yaml"
    $gatewayFile = "gateway.yaml"
    $applyServiceCommand = "kubectl apply -f $serviceFile -f $cronJobFile -f $gatewayFile"
    az aks command invoke --resource-group $resourceGroup --name $clusterName --command $applyServiceCommand
}

function Add-IstioSidecar {
    $injectIstioCommand = "istioctl kube-inject -f deployment.yaml -i aks-istio-system -r asm-1-21"
    $tempFile = [System.IO.Path]::GetTempFileName()
    & $injectIstioCommand | Out-File -FilePath $tempFile
    $applyIstioCommand = "kubectl apply -f $tempFile"
    az aks command invoke --resource-group $resourceGroup --name $clusterName --command $applyIstioCommand
    Remove-Item -Path $tempFile
}

Set-Location -Path "./backend-printing/k8s"

Get-AksCredentials
New-K8sSecret

Write-Output "Using ACR registry: $acrRegistry"
Write-Output "Substituting image name in deployment template..."
Invoke-K8sDeployment

Write-Output "Applying Kubernetes service, gateway and cronjobs..."
Invoke-K8sServices

Write-Output "Injecting Istio sidecar proxy into the deployment..."
Add-IstioSidecar

Write-Output "Deployment completed successfully."