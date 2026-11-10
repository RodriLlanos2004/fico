-- FICO - esquema del prototipo 1. Idempotente: se puede correr varias veces.
-- Convencion: dias_semana usa ISO (1 = lunes ... 7 = domingo), igual que extract(isodow).

create table if not exists users (
  id               bigint generated always as identity primary key,
  telegram_chat_id bigint unique not null,
  nombre           text not null,
  zona_horaria     text not null default 'America/Mexico_City',
  onboarding_done  boolean not null default false,
  created_at       timestamptz not null default now()
);

create table if not exists memory_facts (
  id         bigint generated always as identity primary key,
  user_id    bigint not null references users(id) on delete cascade,
  categoria  text,
  hecho      text not null,
  created_at timestamptz not null default now()
);

create table if not exists tasks (
  id           bigint generated always as identity primary key,
  user_id      bigint not null references users(id) on delete cascade,
  titulo       text not null,
  notas        text,
  vence        date,
  estado       text not null default 'pendiente' check (estado in ('pendiente', 'hecha')),
  created_at   timestamptz not null default now(),
  completed_at timestamptz
);
create index if not exists tasks_pendientes on tasks (user_id, vence) where estado = 'pendiente';

create table if not exists checklist_items (
  id          bigint generated always as identity primary key,
  user_id     bigint not null references users(id) on delete cascade,
  area        text not null check (area in ('Espiritual', 'Vida', 'Gym', 'Alimentación')),
  titulo      text not null,
  franja      text,
  dias_semana int[] not null default '{1,2,3,4,5,6,7}',
  activo      boolean not null default true,
  orden       int not null default 0
);

create table if not exists checkin_slots (
  id          bigint generated always as identity primary key,
  user_id     bigint not null references users(id) on delete cascade,
  hora        time not null,
  areas       text[] not null,
  dias_semana int[] not null default '{1,2,3,4,5,6,7}',
  activo      boolean not null default true,
  unique (user_id, hora)
);

-- Extra al documento: evita mandar dos veces el mismo check-in (el programador corre cada 15 min).
create table if not exists checkin_sends (
  slot_id    bigint not null references checkin_slots(id) on delete cascade,
  fecha      date not null,
  enviado_en timestamptz not null default now(),
  primary key (slot_id, fecha)
);

create table if not exists checklist_logs (
  id            bigint generated always as identity primary key,
  item_id       bigint not null references checklist_items(id) on delete cascade,
  fecha         date not null,
  cumplido      boolean not null,
  nota          text,
  respondido_en timestamptz not null default now(),
  unique (item_id, fecha)
);

create table if not exists gym_plan (
  id         bigint generated always as identity primary key,
  user_id    bigint not null references users(id) on delete cascade,
  dia_semana int not null check (dia_semana between 1 and 7),
  grupo      text not null,
  ejercicio  text not null,
  series     int,
  reps       text,
  peso_obj   numeric(6,2),
  orden      int not null default 0
);

create table if not exists gym_logs (
  id         bigint generated always as identity primary key,
  user_id    bigint not null references users(id) on delete cascade,
  fecha      date not null,
  ejercicio  text not null,
  series     int,
  reps       text,
  peso       numeric(6,2),
  nota       text,
  created_at timestamptz not null default now()
);

create table if not exists pending_actions (
  id           bigint generated always as identity primary key,
  user_id      bigint not null references users(id) on delete cascade,
  tool         text not null,
  payload_json jsonb not null,
  estado       text not null default 'pendiente'
               check (estado in ('pendiente', 'aprobada', 'rechazada', 'expirada', 'ejecutada', 'fallida')),
  expires_at   timestamptz not null default now() + interval '10 minutes',
  created_at   timestamptz not null default now(),
  resolved_at  timestamptz
);

create table if not exists pending_local_actions (
  id          bigint generated always as identity primary key,
  user_id     bigint not null references users(id) on delete cascade,
  accion      jsonb not null,
  aplicada    boolean not null default false,
  created_at  timestamptz not null default now(),
  aplicada_en timestamptz
);

create table if not exists agent_logs (
  id             bigint generated always as identity primary key,
  session_id     text,
  canal          text,
  input          text,
  tools_llamadas jsonb,
  output         text,
  tokens_in      int,
  tokens_out     int,
  costo_usd      numeric(10,6),
  latencia_ms    int,
  error          text,
  created_at     timestamptz not null default now()
);
create index if not exists agent_logs_fecha on agent_logs (created_at);

-- Tabla que usa el nodo Postgres Chat Memory de n8n. Se crea aqui porque el rol
-- de n8n no tiene permiso de crear tablas.
create table if not exists n8n_chat_histories (
  id         serial primary key,
  session_id varchar(255) not null,
  message    jsonb not null
);
create index if not exists n8n_chat_histories_sesion on n8n_chat_histories (session_id, id);
