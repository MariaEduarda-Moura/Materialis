param(
    [string]$DockerHubUser = "mariaeduardamoura",
    [string]$ImageName = "materialis",
    [string]$ImageTag = "latest",
    [string]$MinikubeProfile = "minikube",
    [switch]$SkipPush,
    [switch]$SkipLoad
)

$ErrorActionPreference = "Stop"

function Assert-Command {
    param([string]$Name)

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Comando '$Name' nao encontrado. Instale antes de continuar."
    }
}

Assert-Command "docker"
Assert-Command "minikube"

$image = "$DockerHubUser/$ImageName`:$ImageTag"

Write-Host "Construindo imagem Docker $image..."
docker build -t $image .

if (-not $SkipPush) {
    Write-Host "Enviando imagem para Docker Hub..."
    docker push $image
}
else {
    Write-Host "Push ignorado por parametro -SkipPush."
}

if (-not $SkipLoad) {
    Write-Host "Carregando imagem no Minikube..."
    minikube image load $image -p $MinikubeProfile
}
else {
    Write-Host "Load para Minikube ignorado por parametro -SkipLoad."
}

Write-Host "Imagem pronta: $image"
