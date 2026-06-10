#!/bin/bash
# =============================================================================
# setup_docker.sh
# Script de inicializacao do servidor Windrose via Docker — EC2 User Data.
# Roda automaticamente na PRIMEIRA inicializacao da instancia.
#
# Imagem: indifferentbroccoli/windrose-server-docker
# Referencia: https://github.com/indifferentbroccoli/windrose-server-docker
#
# O que este script faz:
#   1. Atualiza o sistema e instala Docker + docker-compose-plugin
#   2. Cria o arquivo .env com as configuracoes do servidor
#   3. Cria o docker-compose.yml
#   4. Sobe o container do Windrose
#   5. Configura o container para iniciar automaticamente com o sistema
# =============================================================================

set -euo pipefail

LOG_FILE="/var/log/windrose-setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

log "=== Iniciando setup do Windrose Dedicated Server (Docker) ==="

SERVER_DIR="/opt/windrose"

# --- 1. Instalar Docker ---
log "[1/4] Instalando Docker..."
apt-get update -qq
apt-get install -y -qq ca-certificates curl gnupg lsb-release

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -qq
apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin

systemctl enable docker
systemctl start docker
log "Docker instalado e iniciado"

# --- 2. Criar diretorio e arquivo .env ---
# IMPORTANTE: heredoc sem aspas simples para permitir substituicao
# das variaveis pelo templatefile do Terraform.
log "[2/4] Criando configuracao do servidor..."
mkdir -p "$SERVER_DIR/server-files"

cat > "$SERVER_DIR/.env" <<ENVEOF
PUID=1000
PGID=1000
UPDATE_ON_START=${update_on_start}
INVITE_CODE=${invite_code}
SERVER_PORT=${server_port}
SERVER_NAME=${server_name}
SERVER_PASSWORD=${server_password}
MAX_PLAYERS=${max_players}
USE_DIRECT_CONNECTION=${use_direct_connection}
DIRECT_CONNECTION_PROXY_ADDRESS=0.0.0.0
P2P_PROXY_ADDRESS=127.0.0.1
ENVEOF

log ".env criado em $SERVER_DIR/.env"

# --- 3. Criar docker-compose.yml ---
# IMPORTANTE: heredoc sem aspas simples para permitir substituicao
# da variavel ${server_port} pelo templatefile do Terraform.
log "[3/4] Criando docker-compose.yml..."
cat > "$SERVER_DIR/docker-compose.yml" <<COMPOSEEOF
services:
  windrose:
    image: indifferentbroccoli/windrose-server-docker
    platform: linux/amd64
    restart: unless-stopped
    container_name: windrose
    stop_grace_period: 30s
    ports:
      - '${server_port}:${server_port}/tcp'
      - '${server_port}:${server_port}/udp'
    env_file:
      - .env
    volumes:
      - ./server-files:/home/steam/server-files
COMPOSEOF

log "docker-compose.yml criado em $SERVER_DIR/docker-compose.yml"

# --- 4. Subir o container ---
log "[4/4] Subindo container do Windrose..."
cd "$SERVER_DIR"
docker compose pull
docker compose up -d

log "Container iniciado. Verificando status:"
docker compose ps

log "=== Setup concluido com sucesso! ==="
log "Invite Code   : ${invite_code}"
log "Conexao direta: <IP_PUBLICO>:${server_port}"
log "Log completo  : $LOG_FILE"
log "Logs do jogo  : docker compose -f $SERVER_DIR/docker-compose.yml logs -f"
