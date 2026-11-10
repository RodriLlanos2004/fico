-- FICO - RLS y rol de minimo privilegio para n8n. Idempotente.
-- La contrasena del rol NO va en este archivo. Despues de correrlo, ejecuta a mano
-- en el SQL Editor de Supabase (y no lo guardes en ningun lado mas que en n8n):
--   alter role fico_n8n with password '<contrasena larga aleatoria>';

do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'fico_n8n') then
    create role fico_n8n login;
  end if;
end $$;

grant usage on schema public to fico_n8n;

do $$
declare
  t text;
begin
  foreach t in array array[
    'users', 'memory_facts', 'tasks', 'checklist_items', 'checkin_slots', 'checkin_sends',
    'checklist_logs', 'gym_plan', 'gym_logs', 'pending_actions', 'pending_local_actions',
    'agent_logs', 'n8n_chat_histories'
  ] loop
    execute format('alter table %I enable row level security', t);
    -- Las llaves publicas de Supabase (anon / authenticated) no tocan nada.
    execute format('revoke all on %I from anon, authenticated', t);
    execute format('grant select, insert, update, delete on %I to fico_n8n', t);
    execute format('drop policy if exists fico_n8n_all on %I', t);
    execute format('create policy fico_n8n_all on %I for all to fico_n8n using (true) with check (true)', t);
  end loop;
end $$;

-- Unica secuencia clasica (serial); las demas tablas usan identity.
grant usage on sequence n8n_chat_histories_id_seq to fico_n8n;
