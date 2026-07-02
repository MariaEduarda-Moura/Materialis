#!/bin/bash

# Configurações padrão
PROFILE="minikube"
DRIVER="docker"
NAMESPACE="materialis"
UPDATE_HOSTS=false
HOSTS_IP="127.0.0.1"

# Processa argumentos/flags
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

set -e

# Função para validar comandos
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

# Verifica se o minikube está rodando
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

    echo "Atualizando o arquivo $HOSTS_PATH (Pode pedir sua senha do Linux)..."
    
    # Usa sudo apenas aqui para editar o arquivo
    sudo sed -i '/k8s\.local/d' "$HOSTS_PATH"
    sudo sed -i '/mail\.k8s\.local/d' "$HOSTS_PATH"

    # Adiciona as novas entradas usando tee com sudo
    echo "$HOSTS_IP k8s.local" | sudo tee -a "$HOSTS_PATH" >/dev/null
    echo "$HOSTS_IP mail.k8s.local" | sudo tee -a "$HOSTS_PATH" >/dev/null

    echo "Arquivo hosts atualizado com:"
    echo "$HOSTS_IP k8s.local"
    echo "$HOSTS_IP mail.k8s.local"
else
    echo ""
    echo "Para atualizar o hosts automaticamente, rode a flag --update-hosts."
fi

echo ""
echo "No Linux com driver Docker, para publicar o Ingress você pode expor a porta usando:"
echo "minikube tunnel"