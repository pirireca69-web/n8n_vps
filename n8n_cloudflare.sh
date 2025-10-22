#!/usr/bin/env bash
set -euo pipefail

echo "🧱 Stopping Docker Compose..."
sudo -E docker compose down || true
echo "✅ Docker Compose stopped."

read -rp "🌍 Hostname público (ex: n8n.seudominio.com): " HOST
read -rp "🔑 Token do Cloudflare Tunnel (copiado do painel): " TOKEN

cat > .env <<EOF
PUBLIC_BASE_URL=https://$HOST
HOSTNAME_PUBLICO=$HOST
CLOUDFLARE_TUNNEL_TOKEN=$TOKEN
EOF

cat > compose.cloudflare.yaml <<'YAML'
services:
  n8n:
    environment:
      - PUBLIC_BASE_URL=https://${HOSTNAME_PUBLICO}

  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    command: tunnel --no-autoupdate run --protocol http2 --token ${CLOUDFLARE_TUNNEL_TOKEN}
    depends_on:
      - n8n
    restart: unless-stopped
YAML

echo "🚀 Starting Docker Compose (n8n + cloudflared)..."
sudo -E docker compose -f compose.yaml -f compose.cloudflare.yaml up -d --force-recreate

echo "✅ Tudo pronto! Aguarda 1 minuto e visita:"
echo "🔗 https://$HOST"
