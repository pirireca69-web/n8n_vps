#!/usr/bin/env bash
set -euo pipefail

echo "🧱 Stopping Docker Compose..."
sudo -E docker compose down || true
echo "✅ Docker Compose stopped."

# --- pedir dados ---
read -rp "🌐 Hostname público (ex: n8n.teu-dominio.com): " CF_HOSTNAME
read -rp "🔑 Cloudflare Tunnel TOKEN (copiado do dashboard): " CF_TOKEN

# --- .env com variáveis úteis ---
# o teu compose usa N8N_EDITOR_BASE_URL/WEBHOOK_URL; vamos apontar para HTTPS do domínio
# e forçar secure cookies porque agora temos HTTPS
echo "🧩 Updating .env..."
touch .env
grep -q "^PUBLIC_BASE_URL=" .env 2>/dev/null || echo "PUBLIC_BASE_URL=https://${CF_HOSTNAME}" >> .env
grep -q "^CLOUDFLARE_TUNNEL_TOKEN=" .env 2>/dev/null || echo "CLOUDFLARE_TUNNEL_TOKEN=${CF_TOKEN}" >> .env

# --- override de compose para 1) injetar HTTPS no n8n e 2) adicionar o cloudflared ---
echo "📝 Writing compose override (compose.cloudflare.yaml)..."
cat > compose.cloudflare.yaml <<'YAML'
services:
  svr_n8n:
    environment:
      - N8N_EDITOR_BASE_URL=${PUBLIC_BASE_URL}
      - WEBHOOK_URL=${PUBLIC_BASE_URL}
      - N8N_SECURE_COOKIE=true
    # opcional: se quiseres fechar a porta 80 externa porque vais usar apenas o túnel,
    # descomenta as 2 linhas abaixo para remover o publish.
    # ports: []
    # expose:
    #   - "5678"

  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    command: tunnel --no-autoupdate run --token ${CLOUDFLARE_TUNNEL_TOKEN}
    depends_on:
      - n8n
    restart: unless-stopped
YAML

echo "🚀 Starting Docker Compose (n8n + cloudflared)..."
sudo -E docker compose -f compose.yaml -f compose.cloudflare.yaml up -d

echo "✅ Done!"
echo "👉 Vai ao painel do Tunnel e confirma o estado: HEALTHY."
echo "🌐 Abre: https://${CF_HOSTNAME}"
