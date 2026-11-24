create table if not exists public.auth_handoffs (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  expires_at timestamptz not null,
  consumido_em timestamptz,
  criado_em timestamptz not null default now()
);

alter table public.auth_handoffs enable row level security;

revoke all on public.auth_handoffs from public, anon, authenticated;
grant select, insert, update, delete on public.auth_handoffs to service_role;

create index if not exists auth_handoffs_pendentes_idx
  on public.auth_handoffs (expires_at)
  where consumido_em is null;

create index if not exists auth_handoffs_usuario_idx
  on public.auth_handoffs (user_id);
