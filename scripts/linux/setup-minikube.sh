#!/bin/bash

# Configurações padrão (simulando os parâmetros do PowerShell)
PROFILE="minikube"
DRIVER="docker"
NAMESPACE="materialis"
UPDATE_HOSTS=false
HOSTS_IP="127.0.0.1"

# Processa argumentos/flags da linha de comando
# Exemplo de uso: ./setup-minikube.sh --update-hosts --hosts-ip 127.0.0.1
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --profile) PROFILE="$2"; shift ;;
        --driver) DRIVER="$2"; shift ;;
        --namespace) NAMESPACE="$2"; shift ;;
        --update-hosts) UPDATE_HOSTS=true ;;
        --hosts-ip) HOSTS_IP="$2"; shift ;;
        *) echo "Parâmetro desconhecido: $1"; exit 1 ;;
    esac
    shift
done

# Ativa o "fail-fast" (para o script imediatamente se qualquer comando falhar)
set -e

# Função para validar se os comandos necessários estão instalados
assert_command() {
    local cmd=$1
    if ! command -v "$cmd" &> /dev/null; then
        echo "Erro: Comando '$cmd' não encontrado. Instale antes de continuar." >&2
        exit 1
    fi
}

assert_command "minikube"
assert_command "kubectl"
assert_command "helm"

# Desativa temporariamente o "set -e" apenas para checar o status do minikube 
# sem fechar o script caso ele não esteja rodando.
set +e
STATUS=$(minikube status -p "$PROFILE" --format "{{.Host}}" 2>/dev/null)
EXIT_CODE=$?
set -e

if [ $EXIT_CODE -ne 0 ] || [ "$STATUS" != "Running" ]; then
    echo "Iniciando Minikube com driver $DRIVER..."
    minikube start -p "$PROFILE" --driver="$DRIVER"
else
    echo "Minikube já está em execução."
fi

echo "Habilitando addon ingress..."
minikube addons enable ingress -p "$PROFILE"

echo "Aguardando ingress-nginx-controller ficar pronto..."
kubectl rollout status deployment/ingress-nginx-controller -n ingress-nginx --timeout=180s

echo "Criando namespace $NAMESPACE, se necessário..."
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

if [ "$UPDATE_HOSTS" = true ]; then
    HOSTS_PATH="/etc/hosts"

    # Verifica se o script está rodando com privilégios de root (sudo)
    if [ "$EUID" -ne 0 ]; then
        echo "Erro: Use 'sudo' para executar o script e atualizar o arquivo /etc/hosts." >&2
        exit 1
    fi

    echo "Atualizando o arquivo $HOSTS_PATH..."
    
    # Remove linhas antigas contendo os domínios locais para evitar duplicatas
    sed -i '/k8s\.local/d' "$HOSTS_PATH"
    sed -i '/mail\.k8s\.local/d' "$HOSTS_PATH"

    # Adiciona as novas entradas
    echo "$HOSTS_IP k8s.local" >> "$HOSTS_PATH"
    echo "$HOSTS_IP mail.k8s.local" >> "$HOSTS_PATH"

    echo "Arquivo hosts atualizado com:"
    echo "$HOSTS_IP k8s.local"
    echo "$HOSTS_IP mail.k8s.local"
else
    echo ""
    echo "Para atualizar o hosts automaticamente, rode com sudo passando a flag:"
    echo "sudo $0 --update-hosts --hosts-ip 127.0.0.1"
fi

echo ""
echo "No Linux com driver Docker, para publicar o Ingress você pode expor a porta usando:"
echo "minikube tunnel"
echo "ou, se preferir um port-forward tradicional na porta 80:"
echo "sudo kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 80:80"