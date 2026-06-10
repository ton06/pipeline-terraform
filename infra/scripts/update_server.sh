#!/bin/bash
# =============================================================================
# update_server.sh
# Atualiza o Windrose Dedicated Server para a versao mais recente.
# Uso: sudo /opt/windrose/update_server.sh
# =============================================================================

set -euo pipefail

SERVER_DIR="/opt/windrose"

echo "[1/3] Parando container..."
docker compose -f "$SERVER_DIR/docker-compose.yml" down

echo "[2/3] Baixando imagem mais recente..."
docker compose -f "$SERVER_DIR/docker-compose.yml" pull

echo "[3/3] Reiniciando container com nova imagem..."
docker compose -f "$SERVER_DIR/docker-compose.yml" up -d

echo "Atualizacao concluida!"
docker compose -f "$SERVER_DIR/docker-compose.yml" ps
