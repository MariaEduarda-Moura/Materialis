param(
    [string]$ReleaseName = "materialis",
    [string]$Namespace = "materialis",
    [string]$DockerHubUser = "mariaeduardamoura",
    [string]$ImageName = "materialis",
    [string]$ImageTag = "latest"
)

$ErrorActionPreference = "Stop"

function Assert-Command {
    param([string]$Name)

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Comando '$Name' nao encontrado. Instale antes de continuar."
    }
}

Assert-Command "helm"
Assert-Command "kubectl"

$chartPath = ".\charts\materialis"
$repository = "$DockerHubUser/$ImageName"

Write-Host "Instalando/atualizando release Helm $ReleaseName..."
helm upgrade --install $ReleaseName $chartPath `
    --namespace $Namespace `
    --create-namespace `
    --set namespace=$Namespace `
    --set image.repository=$repository `
    --set image.tag=$ImageTag

Write-Host ""
Write-Host "Recursos criados:"
kubectl get pods,svc,ingress,pvc -n $Namespace

Write-Host ""
Write-Host "Aplicacao: http://k8s.local"
Write-Host "Mailpit: http://mail.k8s.local"
Write-Host "No Windows com driver Docker, talvez seja necessario manter aberto:"
Write-Host "minikube service ingress-nginx-controller -n ingress-nginx --url"
