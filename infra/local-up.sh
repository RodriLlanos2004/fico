#!/usr/bin/env bash
# Levanta FICO en la laptop. Correr despues de cada reinicio: bash infra/local-up.sh
# El tunel gratuito da una URL nueva cada vez; n8n se recrea con esa URL y rehook.sh
# vuelve a registrar el webhook de Telegram. La URL de Siri hay que actualizarla en el atajo.
set -euo pipefail
cd "$(dirname "$0")"
docker info >/dev/null 2>&1 || { echo "Docker no esta corriendo. Abre Docker Desktop, espera a que diga 'Engine running' y vuelve a intentar."; exit 1; }
C="docker compose -p fico-local -f docker-compose.local.yml --env-file .env.local"

# Secretos locales, generados una sola vez. No se imprimen.
[ -f .env.local ] || ( umask 077
  printf 'N8N_ENCRYPTION_KEY=%s\nSIRI_TOKEN=%s\n' "$(openssl rand -hex 32)" "$(openssl rand -hex 32)" > .env.local )

mkdir -p ../n8n/workflows
$C up -d --force-recreate tunnel 2>/dev/null

URL=""
for _ in $(seq 1 40); do
  URL=$($C logs tunnel 2>&1 | grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' | head -1 || true)
  [ -n "$URL" ] && break
  sleep 1
done
[ -n "$URL" ] || { echo "El tunel no dio URL. Revisa: $C logs tunnel"; exit 1; }

FICO_URL="$URL" $C up -d n8n 2>/dev/null
echo "$URL" > .tunnel-url
echo "Editor:   http://localhost:5678"
echo "Publico:  $URL"
./rehook.sh || true
