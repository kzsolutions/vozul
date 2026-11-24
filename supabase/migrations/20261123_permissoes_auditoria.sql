-- Catálogo de permissões e matriz por perfil/admin.
create table if not exists public.permissoes (
  chave text primary key,
  rotulo text not null,
  descricao text,
  modulo text not null default 'geral',
  ativo boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.permissoes enable row level security;

drop policy if exists "admin_ve_permissoes" on public.permissoes;
create policy "admin_ve_permissoes"
on public.permissoes for select to authenticated
using (true);

create table if not exists public.perfil_permissoes (
  role text not null check (role in ('admin', 'super_admin')),
  permissao_chave text not null references public.permissoes(chave) on delete cascade,
  permitido boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (role, permissao_chave)
);

alter table public.perfil_permissoes enable row level security;

drop policy if exists "admin_ve_perfil_permissoes" on public.perfil_permissoes;
create policy "admin_ve_perfil_permissoes"
on public.perfil_permissoes for select to authenticated
using (true);

drop policy if exists "super_admin_gerir_perfil_permissoes" on public.perfil_permissoes;
create policy "super_admin_gerir_perfil_permissoes"
on public.perfil_permissoes for all to authenticated
using (public.is_super_admin())
with check (public.is_super_admin());

create table if not exists public.admin_permissoes (
  usuario_id uuid not null references public.profiles(id) on delete cascade,
  permissao_chave text not null references public.permissoes(chave) on delete cascade,
  permitido boolean not null,
  updated_by uuid references public.profiles(id) on delete set null default auth.uid(),
  updated_at timestamptz not null default now(),
  primary key (usuario_id, permissao_chave)
);

alter table public.admin_permissoes enable row level security;

drop policy if exists "admin_ve_proprias_permissoes" on public.admin_permissoes;
create policy "admin_ve_proprias_permissoes"
on public.admin_permissoes for select to authenticated
using (public.is_super_admin() or usuario_id = auth.uid());

drop policy if exists "super_admin_gerir_admin_permissoes" on public.admin_permissoes;
create policy "super_admin_gerir_admin_permissoes"
on public.admin_permissoes for all to authenticated
using (public.is_super_admin())
with check (public.is_super_admin());

-- Permissão efetiva: ajuste individual > predefinição do perfil > negado.
create or replace function public.tem_permissao(
  p_chave text,
  p_usuario uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path to 'public'
as $function$
  select coalesce(
    (select ap.permitido from public.admin_permissoes ap
      where ap.usuario_id = p_usuario and ap.permissao_chave = p_chave),
    (select pp.permitido from public.perfil_permissoes pp
      join public.profiles pr on pr.role::text = pp.role
      where pr.id = p_usuario and pp.permissao_chave = p_chave),
    false
  );
$function$;

insert into public.permissoes (chave, rotulo, descricao, modulo, ativo) values
  ('denuncias.ler', 'Ver denúncias', 'Consultar denúncias do âmbito', 'denuncias', true),
  ('denuncias.responder', 'Responder denúncias', 'Enviar mensagens na conversa da comissão', 'mensagens', true),
  ('provas.ler', 'Ver provas', 'Consultar anexos e evidências', 'denuncias', true),
  ('relatorios.ver', 'Ver relatórios', 'Consultar estatísticas e exportar relatórios', 'relatorios', true),
  ('historico.ver', 'Ver histórico', 'Consultar registos de acesso', 'auditoria', true),
  ('administradores.gerir', 'Gerir administradores', 'Criar, alterar e remover contas de gestão', 'administracao', true),
  ('permissoes.gerir', 'Gerir permissões', 'Alterar matriz de permissões', 'administracao', true),
  ('auditoria.ver', 'Ver auditoria', 'Consultar registos de auditoria', 'auditoria', true),
  ('configuracoes.gerir', 'Gerir configurações', 'Alterar configurações do painel', 'administracao', true)
on conflict (chave) do update set
  rotulo = excluded.rotulo,
  descricao = excluded.descricao,
  modulo = excluded.modulo,
  ativo = excluded.ativo;

insert into public.perfil_permissoes (role, permissao_chave, permitido) values
  ('admin', 'denuncias.ler', true),
  ('admin', 'denuncias.responder', true),
  ('admin', 'provas.ler', true),
  ('admin', 'relatorios.ver', true),
  ('admin', 'historico.ver', false),
  ('admin', 'administradores.gerir', false),
  ('admin', 'permissoes.gerir', false),
  ('admin', 'auditoria.ver', false),
  ('admin', 'configuracoes.gerir', false),
  ('super_admin', 'denuncias.ler', true),
  ('super_admin', 'denuncias.responder', false),
  ('super_admin', 'provas.ler', true),
  ('super_admin', 'relatorios.ver', true),
  ('super_admin', 'historico.ver', true),
  ('super_admin', 'administradores.gerir', true),
  ('super_admin', 'permissoes.gerir', true),
  ('super_admin', 'auditoria.ver', true),
  ('super_admin', 'configuracoes.gerir', true)
on conflict (role, permissao_chave) do update set
  permitido = excluded.permitido,
  updated_at = now();

-- Colunas adicionais para o AuditLog persistido.
alter table public.historico_acessos add column if not exists recurso text;
alter table public.historico_acessos add column if not exists registro_id text;
create index if not exists historico_acessos_recurso_idx
on public.historico_acessos (recurso, created_at desc);
