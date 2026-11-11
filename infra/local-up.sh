#!/usr/bin/env bash
# Levanta FICO en la laptop con una URL publica fija (dominio gratuito de ngrok).
# Correr despues de cada reinicio: bash infra/local-up.sh
set -euo pipefail
cd "$(dirname "$0")"
docker info >/dev/null 2>&1 || { echo "Docker no esta corriendo. Abre Docker Desktop, espera a que diga 'Engine running' y vuelve a intentar."; exit 1; }

# Secretos locales, generados una sola vez. No se imprimen.
[ -f .env.local ] || ( umask 077
  printf 'N8N_ENCRYPTION_KEY=%s\nSIRI_TOKEN=%s\n' "$(openssl rand -hex 32)" "$(openssl rand -hex 32)" > .env.local )
. ./.env.local
[ -n "${NGROK_AUTHTOKEN:-}" ] && [ -n "${NGROK_DOMAIN:-}" ] || {
  echo "Faltan NGROK_AUTHTOKEN y NGROK_DOMAIN en infra/.env.local."
  echo "Los dos salen de https://dashboard.ngrok.com (Your Authtoken y Domains)."
  exit 1; }

URL="https://${NGROK_DOMAIN}"
ANTES="$(cat .tunnel-url 2>/dev/null || true)"
mkdir -p ../n8n/workflows
FICO_URL="$URL" docker compose -p fico-local -f docker-compose.local.yml --env-file .env.local up -d --remove-orphans 2>/dev/null
echo "$URL" > .tunnel-url
echo "Editor:   http://localhost:5678"
echo "Publico:  $URL"

# Telegram solo necesita re-registrarse si la URL cambio.
[ "$ANTES" = "$URL" ] || ./rehook.sh || true
