param(
    [string]$ReleaseName = "materialis",
    [string]$Namespace = "materialis",
    [switch]$RemovePersistentVolumeClaim,
    [switch]$RemoveNamespace
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command "helm" -ErrorAction SilentlyContinue)) {
    throw "Comando 'helm' nao encontrado."
}

if (-not (Get-Command "kubectl" -ErrorAction SilentlyContinue)) {
    throw "Comando 'kubectl' nao encontrado."
}

Write-Host "Removendo release Helm $ReleaseName..."
helm uninstall $ReleaseName -n $Namespace

if ($RemovePersistentVolumeClaim) {
    Write-Host "Removendo PVCs do namespace $Namespace..."
    kubectl delete pvc -n $Namespace --all --ignore-not-found
}

if ($RemoveNamespace) {
    Write-Host "Removendo namespace $Namespace..."
    kubectl delete namespace $Namespace --ignore-not-found
}

Write-Host "Remocao concluida."
