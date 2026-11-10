# FICO

Agente personal de Rodri. Prototipo 1: n8n self-hosted en una e2-micro de Google Cloud (Always Free),
Supabase para datos, Claude Haiku como cerebro, Telegram y un atajo de Siri como canales.

Estado: hito A (infraestructura). Este README crece con cada hito.

## Levantar la infraestructura

Requisitos: proyecto de GCP con facturacion, gcloud autenticado, subdominio y token de DuckDNS.

```bash
PROJECT=<id-del-proyecto> bash infra/gcp-setup.sh
gcloud compute scp --recurse infra fico:~/ --zone us-central1-a --tunnel-through-iap
gcloud compute ssh fico --zone us-central1-a --tunnel-through-iap
sudo bash ~/infra/vm-bootstrap.sh    # ya dentro de la VM
```

Despues abre `https://<subdominio>.duckdns.org` y crea la cuenta owner de n8n.

## Seguridad

- Solo 80 y 443 publicos. SSH unicamente por IAP.
- Secretos en `/opt/fico/infra/.env` (permisos 600), nunca en el repo.
- La VM no tiene cuenta de servicio.

## Costo esperado

VM, disco e IP dentro de Always Free. Gasto variable: Anthropic y OpenAI (objetivo 2 a 3 USD al mes).
