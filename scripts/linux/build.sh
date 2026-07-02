#!/bin/bash

# Configurações padrão
DOCKER_HUB_USER="mariaeduardamoura"
IMAGE_NAME="materialis"
IMAGE_TAG="latest"
MINIKUBE_PROFILE="minikube"
SKIP_PUSH=false
SKIP_LOAD=false

# Processa os argumentos da linha de comando
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --docker-hub-user) DOCKER_HUB_USER="$2"; shift ;;
        --image-name) IMAGE_NAME="$2"; shift ;;
        --image-tag) IMAGE_TAG="$2"; shift ;;
        --minikube-profile) MINIKUBE_PROFILE="$2"; shift ;;
        --skip-push) SKIP_PUSH=true ;;
        --skip-load) SKIP_LOAD=true ;;
        *) echo "Parâmetro desconhecido: $1"; exit 1 ;;
    esac
    shift
done

# Para a execução imediatamente se houver erro (equivalente ao $ErrorActionPreference = "Stop")
set -e

# Função para validar dependências
assert_command() {
    local cmd=$1
    if ! command -v "$cmd" &> /dev/null; then
        echo "Erro: Comando '$cmd' não encontrado. Instale antes de continuar." >&2
        exit 1
    fi
}

assert_command "docker"
assert_command "minikube"

IMAGE="${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}"

echo "Construindo imagem Docker $IMAGE..."
docker build -t "$IMAGE" .

if [ "$SKIP_PUSH" = false ]; then
    echo "Enviando imagem para Docker Hub..."
    docker push "$IMAGE"
else
    echo "Push ignorado por parâmetro --skip-push."
fi

if [ "$SKIP_LOAD" = false ]; then
    echo "Carregando imagem no Minikube..."
    minikube image load "$IMAGE" -p "$MINIKUBE_PROFILE"
else
    echo "Load para Minikube ignorado por parâmetro --skip-load."
fi

echo "Imagem pronta: $IMAGE"