#!/usr/bin/env bash
# Despliega FICO en Supabase: sube los secretos, publica la funcion y registra el webhook de Telegram.
# Uso: bash infra/deploy-supabase.sh
# Requiere supabase/.env.fico (llaves de FICO) y SUPABASE_ACCESS_TOKEN en infra/.env.local.
set -euo pipefail
cd "$(dirname "$0")/.."
. infra/.env.local
REF="${SUPABASE_PROJECT_REF:?Define SUPABASE_PROJECT_REF en infra/.env.local}"
BASE="https://${REF}.supabase.co/functions/v1/fico"
[ -n "${SUPABASE_ACCESS_TOKEN:-}" ] || { echo "Falta SUPABASE_ACCESS_TOKEN en infra/.env.local (https://supabase.com/dashboard/account/tokens)."; exit 1; }
export SUPABASE_ACCESS_TOKEN
for k in FICO_DB_URL FICO_TOKEN TELEGRAM_BOT_TOKEN GEMINI_API_KEY GROQ_API_KEY; do
  grep -Eq "^${k}=.+" supabase/.env.fico || { echo "Falta ${k} en supabase/.env.fico"; exit 1; }
done
if grep -q 'PON-AQUI' supabase/.env.fico; then echo "Reemplaza PON-AQUI-LA-CONTRASENA en supabase/.env.fico"; exit 1; fi

npx -y supabase secrets set --env-file supabase/.env.fico --project-ref "$REF" >/dev/null
echo "Secretos cargados."
# --no-verify-jwt: Telegram no puede mandar un JWT; la funcion valida sus propios tokens.
npx -y supabase functions deploy fico --project-ref "$REF" --no-verify-jwt --use-api
echo "Funcion publicada en $BASE"

TOKEN="$(grep -E '^FICO_TOKEN=' supabase/.env.fico | cut -d= -f2- | tr -d '\r')"
# -K - : el token entra por stdin y no aparece en la lista de procesos.
curl -fsS -X POST -K - "$BASE/setup" <<EOF
header = "Authorization: Bearer ${TOKEN}"
EOF
echo
