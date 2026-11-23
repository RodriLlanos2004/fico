# FICO

Asistente personal de IA que se usa por **Telegram** (texto o nota de voz) y por **Siri** (atajos del iPhone).
Lleva tareas, memoria de largo plazo, un checklist diario por áreas (vida, espiritual, gym y alimentación),
la rutina de gym y acciones del teléfono como alarmas y temporizadores.

## Cómo funciona

```
Telegram ──┐                                   ┌─ Gemini (modelo con function calling)
           ├─► Supabase Edge Function "fico" ──┼─ Groq Whisper (transcribe notas de voz)
Siri ──────┘    (Deno + TypeScript)            └─ Postgres de Supabase (datos, memoria, logs)
```

- **Agente con herramientas:** el modelo decide qué herramienta usar entre 12 (tareas, memoria, checklist, rutina y
  registro de gym, alarmas, temporizadores y estado del sistema). Cada herramienta valida sus argumentos y ejecuta
  **SQL fijo y parametrizado**; el modelo nunca escribe consultas.
- **Memoria:** los últimos mensajes de cada sesión y una tabla de hechos duraderos que se inyecta en cada petición.
- **Acciones del iPhone:** lo que solo puede hacer el teléfono (alarmas, temporizadores) vuelve como
  `acciones_locales` para que el atajo de Siri lo ejecute. Si la orden llegó por Telegram, queda en espera hasta que
  el atajo "FICO acciones" la aplique.
- **Costos medidos:** cada llamada se registra en `agent_logs` con tokens, costo en USD y latencia.

## Seguridad

- Lista de permitidos por `chat_id` antes de cualquier proceso: un chat desconocido no recibe respuesta ni gasta tokens.
- El webhook de Telegram se valida con un secreto propio, derivado del token de FICO; Siri usa `Bearer` con
  comparación en tiempo constante.
- La función se conecta con un rol de Postgres de mínimo privilegio (`fico_n8n`), nunca con `service_role`.
  Row Level Security activo en todas las tablas (`db/003_rls.sql`).
- El contenido que traen las herramientas se trata como datos, nunca como instrucciones (defensa contra prompt injection).
- Ningún secreto vive en el repositorio: `.env` y `.env.*` están en `.gitignore`.

## Estructura

```
supabase/functions/fico/index.ts   el agente completo (rutas, herramientas, ciclo del modelo, Telegram y Siri)
db/                                esquema, datos de ejemplo, RLS y memoria de chat
siri/ATAJO_FICO.md                 cómo armar los dos atajos en la app Atajos
infra/                             despliegue en Supabase y versión anterior con n8n
n8n/                               workflows y system prompt de la versión con n8n
```

## Desplegar

1. Crea un proyecto en Supabase y corre `db/001_schema.sql` a `db/004_memoria_chat.sql` en el editor SQL.
2. Crea `supabase/.env.fico` con `FICO_DB_URL`, `FICO_TOKEN`, `TELEGRAM_BOT_TOKEN`, `GEMINI_API_KEY` y `GROQ_API_KEY`.
3. Crea `infra/.env.local` con `SUPABASE_PROJECT_REF` y `SUPABASE_ACCESS_TOKEN`.
4. Ejecuta `bash infra/deploy-supabase.sh`: sube los secretos, publica la función y registra el webhook de Telegram.
5. Arma los atajos siguiendo `siri/ATAJO_FICO.md`.

## Historia del proyecto

El prototipo 1 se construyó por hitos sobre **n8n** autoalojado en una VM e2-micro de Google Cloud, con Caddy, HTTPS
automático y DuckDNS (`infra/` y `n8n/`). Para llegar a costo cero se migró a una sola Edge Function de Supabase, que
conserva el mismo esquema de datos, las mismas herramientas y el mismo patrón de aprobaciones.
