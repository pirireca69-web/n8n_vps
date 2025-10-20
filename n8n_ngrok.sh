#!/bin/bash

# Stop Docker Compose
echo "🧱 Stopping Docker Compose..."
sudo -E docker compose down
echo "✅ Docker Compose stopped."

# Setup Ngrok
echo "⚙️ Setting up Ngrok..."
wget -q ngrok.tgz https://bin.equinox.io/c/bNyj1mQV4c/ngrok-v3-stable-linux-amd64.tgz
sudo tar xvzf ./ngrok.tgz -C /usr/local/bin
sudo apt install -y jq

# User input for Ngrok token and domain
echo "🔑 Please log in to ngrok.com and provide your auth token and static domain."
read -p "Enter Ngrok Auth Token: " token
read -p "Enter Ngrok Domain: " domain

# Configure and start Ngrok
ngrok config add-authtoken "$token"
ngrok http --url="$domain" 80 > /dev/null &

# Wait for Ngrok to initialize
echo "⏳ Waiting for Ngrok to initialize..."
sleep 8

# Fetch public URL from Ngrok
export EXTERNAL_IP="$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url')"
echo "🌍 Ngrok URL obtained: $EXTERNAL_IP"

echo "✅ Ngrok setup complete."

# Start Docker Compose
echo "🚀 Starting Docker Compose..."
sudo -E docker compose up -d

echo "🎉 All done! Please wait a few minutes and then visit $EXTERNAL_IP to access the n8n UI."
