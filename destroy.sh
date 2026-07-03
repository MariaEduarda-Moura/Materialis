#!/bin/bash

# Configurações padrão
RELEASE_NAME="materialis"
NAMESPACE="materialis"
REMOVE_PVC=false
REMOVE_NAMESPACE=false

# Processa os argumentos da linha de comando
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --release-name) RELEASE_NAME="$2"; shift ;;
        --namespace) NAMESPACE="$2"; shift ;;
        --remove-pvc) REMOVE_PVC=true ;;
        --remove-namespace) REMOVE_NAMESPACE=true ;;
        *) echo "Parâmetro desconhecido: $1"; exit 1 ;;
    esac
    shift
done

# Ativa o "fail-fast" 
set -e

# Função para validar dependências
assert_command() {
    local cmd=$1
    if ! command -v "$cmd" &> /dev/null; then
        echo "Erro: Comando '$cmd' não encontrado." >&2
        exit 1
    fi
}

assert_command "helm"
assert_command "kubectl"

echo "Removendo release Helm $RELEASE_NAME..."
helm uninstall "$RELEASE_NAME" -n "$NAMESPACE"

if [ "$REMOVE_PVC" = true ]; then
    echo "Removendo PVCs do namespace $NAMESPACE..."
    kubectl delete pvc -n "$NAMESPACE" --all --ignore-not-found
fi

if [ "$REMOVE_NAMESPACE" = true ]; then
    echo "Removendo namespace $NAMESPACE..."
    kubectl delete namespace "$NAMESPACE" --ignore-not-found
fi

echo "Remoção concluída."