-- Âmbito dos administradores de nível 2 (3/3): notificações e atribuição.
--
-- Notificações de novas denúncias/mensagens passam a exigir faculdade E
-- delegação. O responsável automático é escolhido dentro do mesmo par.

create or replace function public.notificar_admins_nova_denuncia()
returns trigger
language plpgsql
security definer
set search_path = 'public'
as $$
begin
  insert into public.notificacoes (usuario_id, denuncia_id, titulo, conteudo, lida, via_sms)
  select p.id, new.id,
         'Nova denúncia ' || new.codigo,
         'Foi registada uma denúncia de "' || new.categoria || '".',
         false, true
  from public.profiles p
  where p.role = 'super_admin'
     or (
       p.role = 'admin'
       and p.faculdade = new.faculdade
       and p.polo_id is not null
       and p.polo_id = new.polo_id
     );
  return new;
end;
$$;

create or replace function public.notificar_admins_nova_mensagem()
returns trigger
language plpgsql
security definer
set search_path = 'public'
as $$
declare
  d public.denuncias;
begin
  select * into d from public.denuncias where id = new.denuncia_id;
  if d.id is null then
    return new;
  end if;

  insert into public.notificacoes (usuario_id, denuncia_id, titulo, conteudo, lida, via_sms)
  select p.id, new.denuncia_id,
         'Nova mensagem em ' || d.codigo,
         case
           when new.remetente = 'estudante'
             then 'O estudante enviou uma mensagem na denúncia "' || d.categoria || '".'
           else 'A comissão respondeu à denúncia "' || d.categoria || '".'
         end,
         false, true
  from public.profiles p
  where (
    p.role = 'super_admin'
    or (
      p.role = 'admin'
      and p.faculdade = d.faculdade
      and p.polo_id is not null
      and p.polo_id = d.polo_id
    )
  )
  and p.id is distinct from new.remetente_id;

  return new;
end;
$$;

create or replace function public.obter_admin_faculdade(
  p_faculdade text,
  p_polo text default null
)
returns uuid
language sql
stable
security definer
set search_path = 'public'
as $$
  select p.id
  from public.profiles p
  where p.role = 'admin'
    and p.faculdade = p_faculdade
    and (p_polo is null or p.polo_id is null or p.polo_id = p_polo)
  order by (p.polo_id is not distinct from p_polo) desc,
           (p.polo_id is null) asc,
           p.created_at desc,
           p.id desc
  limit 1;
$$;

create or replace function public.criar_denuncia(
  categoria text,
  categoria_custom text,
  descricao text,
  denunciado_tipo text,
  denunciado_nome text,
  denunciado_numero text,
  denunciado_celular text,
  faculdade text,
  curso text,
  local_ocorrido text,
  data_ocorrido date,
  anonima boolean,
  estudante_id uuid,
  tem_provas boolean,
  email_notificacao text default null,
  p_polo_id text default null
)
returns public.denuncias
language plpgsql
security definer
set search_path = 'public'
as $$
declare
  nova public.denuncias;
  v_polo text := nullif(btrim(coalesce(p_polo_id, '')), '');
begin
  if not public.is_estudante() then
    raise exception 'Apenas estudantes podem criar denúncias' using errcode = '42501';
  end if;

  insert into public.denuncias (
    categoria, categoria_custom, descricao, denunciado_tipo, denunciado_nome,
    denunciado_numero, denunciado_celular, polo_id, faculdade, curso,
    local_ocorrido, data_ocorrido, anonima, estudante_id, tem_provas,
    email_notificacao, admin_responsavel
  )
  values (
    categoria, categoria_custom, descricao, denunciado_tipo, denunciado_nome,
    denunciado_numero, denunciado_celular, v_polo, faculdade, curso,
    local_ocorrido, data_ocorrido, anonima, estudante_id, tem_provas,
    case when btrim(coalesce(email_notificacao, '')) = '' then null else lower(btrim(email_notificacao)) end,
    public.obter_admin_faculdade(faculdade, v_polo)
  )
  returning * into nova;

  if auth.uid() is not null then
    insert into public.participantes_denuncia (denuncia_id, usuario_id)
    values (nova.id, auth.uid())
    on conflict (denuncia_id, usuario_id) do nothing;
  end if;

  return nova;
end;
$$;
