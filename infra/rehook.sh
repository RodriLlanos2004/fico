#!/usr/bin/env bash
# Vuelve a registrar el webhook de Telegram en la URL publica actual.
# n8n no lo hace solo al reiniciar: hay que desactivar y activar el workflow 01.
# Requiere N8N_API_KEY en infra/.env.local (n8n > Settings > n8n API > Create an API key).
set -euo pipefail
cd "$(dirname "$0")"
. ./.env.local
[ -n "${N8N_API_KEY:-}" ] || { echo "Falta N8N_API_KEY en infra/.env.local. Mientras tanto: en n8n abre el workflow 01, despublicalo y publicalo de nuevo."; exit 1; }

for _ in $(seq 1 60); do curl -fsS http://localhost:5678/healthz >/dev/null 2>&1 && break; sleep 2; done
sleep 5
for accion in deactivate activate; do
  # -K - : la llave entra por stdin y no aparece en la lista de procesos.
  curl -fsS -o /dev/null -X POST -K - <<EOF
url = "http://localhost:5678/api/v1/workflows/fico01telegram/${accion}"
header = "X-N8N-API-KEY: ${N8N_API_KEY}"
EOF
done
echo "Webhook de Telegram registrado en la URL actual."
