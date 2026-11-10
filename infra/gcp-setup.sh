#!/usr/bin/env bash
# Crea la VM y el firewall de FICO. Idempotente.
# Uso: PROJECT=<id-del-proyecto> bash infra/gcp-setup.sh
set -euo pipefail
PROJECT="${PROJECT:?Define PROJECT=<id del proyecto de GCP>}"
ZONE="${ZONE:-us-central1-a}"
VM=fico

gcloud config set project "$PROJECT"
gcloud services enable compute.googleapis.com iap.googleapis.com

# e2-micro Always Free: us-central1, disco estandar de 30 GB, sin cuenta de servicio.
gcloud compute instances describe "$VM" --zone "$ZONE" >/dev/null 2>&1 ||
gcloud compute instances create "$VM" --zone "$ZONE" \
  --machine-type e2-micro \
  --image-family debian-12 --image-project debian-cloud \
  --boot-disk-size 30GB --boot-disk-type pd-standard \
  --tags fico-web \
  --no-service-account --no-scopes \
  --shielded-secure-boot

# Firewall: 80/443 publicos; SSH solo desde el rango de IAP.
gcloud compute firewall-rules describe fico-web >/dev/null 2>&1 ||
gcloud compute firewall-rules create fico-web \
  --allow tcp:80,tcp:443 --target-tags fico-web --source-ranges 0.0.0.0/0
gcloud compute firewall-rules describe fico-ssh-iap >/dev/null 2>&1 ||
gcloud compute firewall-rules create fico-ssh-iap \
  --allow tcp:22 --source-ranges 35.235.240.0/20
# Reglas abiertas que trae la red default en proyectos nuevos.
for r in default-allow-ssh default-allow-rdp; do
  gcloud compute firewall-rules delete "$r" --quiet 2>/dev/null || true
done

echo
echo "VM lista. Reglas de firewall vigentes:"
gcloud compute firewall-rules list --format="table(name,sourceRanges.list(),allowed[].map().firewall_rule().list())"
echo
echo "Siguiente:"
echo "  gcloud compute scp --recurse infra $VM:~/ --zone $ZONE --tunnel-through-iap"
echo "  gcloud compute ssh $VM --zone $ZONE --tunnel-through-iap"
echo "  sudo bash ~/infra/vm-bootstrap.sh"
