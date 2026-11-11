-- FICO - esquema propio para la memoria de chat. Idempotente. Correr despues de 003_rls.sql.
-- El nodo Postgres Chat Memory de n8n ejecuta "create table if not exists" en cada uso, y
-- Postgres exige permiso de crear en el esquema aunque la tabla ya exista. En vez de darle
-- a fico_n8n permiso de crear en public, la tabla vive en un esquema aparte donde si puede.

create schema if not exists fico_mem;
grant usage, create on schema fico_mem to fico_n8n;

do $$
begin
  if to_regclass('public.n8n_chat_histories') is not null then
    alter table public.n8n_chat_histories set schema fico_mem;
  end if;
end $$;

-- Las consultas sin esquema de este rol buscan primero en fico_mem y luego en public.
alter role fico_n8n set search_path = fico_mem, public;
