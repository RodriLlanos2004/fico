#!/usr/bin/env bash
# Actualiza la IP en DuckDNS (cron cada 5 min). La IP de la VM es efimera.
set -euo pipefail
cd "$(dirname "$0")"
. ./.env
# -K - : la URL con el token entra por stdin y no aparece en la lista de procesos.
curl -fsS -K - <<EOF | grep -q '^OK'
url = "https://www.duckdns.org/update?domains=${DUCKDNS_SUBDOMAIN}&token=${DUCKDNS_TOKEN}&ip="
EOF
