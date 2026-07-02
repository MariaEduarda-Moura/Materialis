param(
    [string]$Profile = "minikube",
    [string]$Driver = "docker",
    [string]$Namespace = "materialis",
    [switch]$UpdateHosts,
    [string]$HostsIp = "127.0.0.1"
)

$ErrorActionPreference = "Stop"

function Assert-Command {
    param([string]$Name)

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Comando '$Name' nao encontrado. Instale antes de continuar."
    }
}

Assert-Command "minikube"
Assert-Command "kubectl"
Assert-Command "helm"

$status = minikube status -p $Profile --format "{{.Host}}" 2>$null
if ($LASTEXITCODE -ne 0 -or $status -ne "Running") {
    Write-Host "Iniciando Minikube com driver $Driver..."
    minikube start -p $Profile --driver=$Driver
}
else {
    Write-Host "Minikube ja esta em execucao."
}

Write-Host "Habilitando addon ingress..."
minikube addons enable ingress -p $Profile

Write-Host "Aguardando ingress-nginx-controller ficar pronto..."
kubectl rollout status deployment/ingress-nginx-controller -n ingress-nginx --timeout=180s

Write-Host "Criando namespace $Namespace, se necessario..."
kubectl create namespace $Namespace --dry-run=client -o yaml | kubectl apply -f -

if ($UpdateHosts) {
    $hostsPath = "C:\Windows\System32\drivers\etc\hosts"
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        throw "Execute o PowerShell como Administrador para atualizar o arquivo hosts."
    }

    $content = Get-Content $hostsPath -ErrorAction Stop
    $content = $content |
        Where-Object { $_ -notmatch '^\s*\S+\s+k8s\.local\s*$' } |
        Where-Object { $_ -notmatch '^\s*\S+\s+mail\.k8s\.local\s*$' }

    $content += "$HostsIp k8s.local"
    $content += "$HostsIp mail.k8s.local"
    Set-Content -Path $hostsPath -Value $content
    ipconfig /flushdns | Out-Null

    Write-Host "Arquivo hosts atualizado com:"
    Write-Host "$HostsIp k8s.local"
    Write-Host "$HostsIp mail.k8s.local"
}
else {
    Write-Host "Para atualizar o hosts automaticamente, rode como Administrador:"
    Write-Host ".\scripts\windows\setup-minikube.ps1 -UpdateHosts -HostsIp 127.0.0.1"
}

Write-Host ""
Write-Host "No Windows com driver Docker, deixe um destes comandos aberto para publicar o Ingress:"
Write-Host "minikube service ingress-nginx-controller -n ingress-nginx --url"
Write-Host "ou, se a porta 80 estiver livre:"
Write-Host "kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 80:80"
