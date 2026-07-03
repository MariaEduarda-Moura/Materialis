#!/bin/bash

# Configurações padrão
RELEASE_NAME="materialis"
NAMESPACE="materialis"
DOCKER_HUB_USER="mariaeduardamoura"
IMAGE_NAME="materialis"
IMAGE_TAG="latest"

# Processa os argumentos da linha de comando
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --release-name) RELEASE_NAME="$2"; shift ;;
        --namespace) NAMESPACE="$2"; shift ;;
        --docker-hub-user) DOCKER_HUB_USER="$2"; shift ;;
        --image-name) IMAGE_NAME="$2"; shift ;;
        --image-tag) IMAGE_TAG="$2"; shift ;;
        *) echo "Parâmetro desconhecido: $1"; exit 1 ;;
    esac
    shift
done

# Ativa o "fail-fast" 
set -e

# Função para validar se os comandos necessários estão instalados
assert_command() {
    local cmd=$1
    if ! command -v "$cmd" &> /dev/null; then
        echo "Erro: Comando '$cmd' não encontrado. Instale antes de continuar." >&2
        exit 1
    fi
}

assert_command "helm"
assert_command "kubectl"

CHART_PATH="./materialis-chart"
REPOSITORY="${DOCKER_HUB_USER}/${IMAGE_NAME}"

echo "Instalando/atualizando release Helm $RELEASE_NAME..."
helm upgrade --install "$RELEASE_NAME" "$CHART_PATH" \
    --namespace "$NAMESPACE" \
    --create-namespace \
    --set namespace="$NAMESPACE" \
    --set image.repository="$REPOSITORY" \
    --set image.tag="$IMAGE_TAG"

echo ""
echo "Recursos criados:"
kubectl get pods,svc,ingress,pvc -n "$NAMESPACE"

echo ""
echo "Aplicação: http://k8s.local"
echo "Mailpit: http://mail.k8s.local"
echo "No Linux com driver Docker, para o Ingress funcionar localmente, deixe este comando rodando em outro terminal:"
echo "minikube tunnel"