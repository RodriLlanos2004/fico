#!/usr/bin/env bash
# Prepara la VM y levanta n8n + Caddy. Idempotente.
# Uso (dentro de la VM): sudo bash ~/infra/vm-bootstrap.sh
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "Corre con sudo"; exit 1; }
SRC="$(cd "$(dirname "$0")" && pwd)"
DEST=/opt/fico/infra

# Swap de 2 GB (la e2-micro tiene 1 GB de RAM)
if ! swapon --show | grep -q /swapfile; then
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile >/dev/null
  swapon /swapfile
  grep -q '^/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# Paquetes, parches automaticos de seguridad y Docker
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq curl openssl cron unattended-upgrades >/dev/null
command -v docker >/dev/null || curl -fsSL https://get.docker.com | sh

# Archivos
mkdir -p "$DEST"
[ "$SRC" = "$DEST" ] || cp "$SRC"/docker-compose.yml "$SRC"/Caddyfile "$SRC"/duckdns.sh "$SRC"/.env.example "$DEST"/
chmod +x "$DEST/duckdns.sh"
cd "$DEST"

# .env: pide lo de DuckDNS y genera los secretos. No imprime nada.
if [ ! -f .env ]; then
  read -rp "Subdominio DuckDNS (sin .duckdns.org): " SUB
  read -rsp "Token DuckDNS (no se muestra): " TOK; echo
  [ -n "$SUB" ] && [ -n "$TOK" ] || { echo "Faltan datos de DuckDNS"; exit 1; }
  ( umask 077; cat > .env <<EOF
FICO_DOMAIN=${SUB}.duckdns.org
DUCKDNS_SUBDOMAIN=${SUB}
DUCKDNS_TOKEN=${TOK}
N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)
SIRI_TOKEN=$(openssl rand -hex 32)
EOF
  )
fi
chmod 600 .env

# DNS primero (Caddy necesita que el dominio apunte aqui para sacar el certificado)
./duckdns.sh && echo "DuckDNS actualizado" || { echo "DuckDNS fallo: revisa subdominio y token en $DEST/.env"; exit 1; }
echo "*/5 * * * * root $DEST/duckdns.sh >/dev/null 2>&1" > /etc/cron.d/fico-duckdns

docker compose pull -q
docker compose up -d

. ./.env
echo
free -m
echo
echo "Listo. En 1 o 2 minutos abre https://${FICO_DOMAIN} y crea la cuenta owner."
echo "Respalda N8N_ENCRYPTION_KEY fuera de la VM: sudo grep N8N_ENCRYPTION_KEY $DEST/.env"
