-- Âmbito dos administradores de nível 2 (2/3): RLS e RPC de conversas.
--
-- O administrador de nível 2 só vê/gerencia denúncias da sua faculdade na sua
-- delegação. O super administrador continua com visão global.

drop policy if exists "admin_ve_denuncias_faculdade" on public.denuncias;
create policy "admin_ve_denuncias_faculdade" on public.denuncias
  for select to authenticated
  using (
    public.is_admin() and (
      public.is_super_admin()
      or (
        faculdade = public.current_user_faculdade()
        and (
          public.current_user_polo() is null
          or polo_id = public.current_user_polo()
        )
      )
    )
  );

drop policy if exists "admin_atualiza_denuncias" on public.denuncias;
create policy "admin_atualiza_denuncias" on public.denuncias
  for update to authenticated
  using (
    public.is_admin() and (
      public.is_super_admin()
      or (
        faculdade = public.current_user_faculdade()
        and (
          public.current_user_polo() is null
          or polo_id = public.current_user_polo()
        )
      )
    )
  )
  with check (
    public.is_admin() and (
      public.is_super_admin()
      or (
        faculdade = public.current_user_faculdade()
        and (
          public.current_user_polo() is null
          or polo_id = public.current_user_polo()
        )
      )
    )
  );

drop policy if exists "admin_ve_evidencias" on public.denuncias_evidencias;
create policy "admin_ve_evidencias" on public.denuncias_evidencias
  for select to authenticated
  using (
    public.is_admin() and exists (
      select 1
        from public.denuncias d
       where d.id = denuncias_evidencias.denuncia_id
         and (
           public.is_super_admin()
           or (
             d.faculdade = public.current_user_faculdade()
             and (
               public.current_user_polo() is null
               or d.polo_id = public.current_user_polo()
             )
           )
         )
    )
  );

drop policy if exists "admin_ve_mensagens" on public.mensagens;
create policy "admin_ve_mensagens" on public.mensagens
  for select to authenticated
  using (
    public.is_admin() and exists (
      select 1
        from public.denuncias d
       where d.id = mensagens.denuncia_id
         and (
           public.is_super_admin()
           or (
             d.faculdade = public.current_user_faculdade()
             and (
               public.current_user_polo() is null
               or d.polo_id = public.current_user_polo()
             )
           )
         )
    )
  );

drop policy if exists "admin_envia_mensagem" on public.mensagens;
create policy "admin_envia_mensagem" on public.mensagens
  for insert to authenticated
  with check (
    remetente = 'comissao'
    and public.is_admin()
    and exists (
      select 1
        from public.denuncias d
       where d.id = mensagens.denuncia_id
         and (
           public.is_super_admin()
           or (
             d.faculdade = public.current_user_faculdade()
             and (
               public.current_user_polo() is null
               or d.polo_id = public.current_user_polo()
             )
           )
         )
    )
  );

drop policy if exists "admin_marca_lida" on public.mensagens;
create policy "admin_marca_lida" on public.mensagens
  for update to authenticated
  using (
    public.is_admin() and exists (
      select 1
        from public.denuncias d
       where d.id = mensagens.denuncia_id
         and (
           public.is_super_admin()
           or (
             d.faculdade = public.current_user_faculdade()
             and (
               public.current_user_polo() is null
               or d.polo_id = public.current_user_polo()
             )
           )
         )
    )
  )
  with check (
    public.is_admin() and exists (
      select 1
        from public.denuncias d
       where d.id = mensagens.denuncia_id
         and (
           public.is_super_admin()
           or (
             d.faculdade = public.current_user_faculdade()
             and (
               public.current_user_polo() is null
               or d.polo_id = public.current_user_polo()
             )
           )
         )
    )
  );

-- A RPC é SECURITY DEFINER: o filtro por faculdade não pode servir de bypass.
create or replace function public.listar_conversas_comissao(p_faculdade text default null)
returns table(
  id bigint,
  codigo text,
  categoria text,
  categoria_custom text,
  descricao text,
  denunciado_tipo text,
  denunciado_nome text,
  denunciado_numero text,
  faculdade text,
  curso text,
  local_ocorrido text,
  data_ocorrido date,
  status text,
  anonima boolean,
  estudante_id uuid,
  tem_provas boolean,
  admin_responsavel uuid,
  created_at timestamp with time zone,
  updated_at timestamp with time zone,
  denunciado_celular text,
  email_notificacao text,
  total_mensagens integer,
  mensagens_estudante integer,
  mensagens_comissao integer,
  nao_lidas integer,
  ultima_mensagem text,
  ultima_mensagem_data timestamp with time zone,
  ultima_mensagem_remetente text
)
language plpgsql
security definer
set search_path = 'public'
as $$
begin
  if not public.is_admin() then
    raise exception 'Acesso negado: apenas a Comissao' using errcode = '42501';
  end if;

  return query
  select
    d.id,
    d.codigo,
    d.categoria,
    d.categoria_custom,
    d.descricao,
    d.denunciado_tipo,
    d.denunciado_nome,
    d.denunciado_numero,
    d.faculdade,
    d.curso,
    d.local_ocorrido,
    d.data_ocorrido,
    d.status,
    d.anonima,
    d.estudante_id,
    d.tem_provas,
    d.admin_responsavel,
    d.created_at,
    d.updated_at,
    d.denunciado_celular,
    d.email_notificacao,
    coalesce(msg.total, 0)::integer,
    coalesce(msg.do_estudante, 0)::integer,
    coalesce(msg.da_comissao, 0)::integer,
    coalesce(msg.por_responder, 0)::integer,
    msg.ultima_conteudo,
    msg.ultima_data,
    msg.ultima_remetente
  from public.denuncias d
  left join lateral (
    select
      count(*)::integer as total,
      count(*) filter (where m.remetente = 'estudante')::integer as do_estudante,
      count(*) filter (where m.remetente = 'comissao')::integer as da_comissao,
      (select count(*)::integer
         from public.mensagens m2
        where m2.denuncia_id = d.id
          and m2.remetente = 'estudante'
          and m2.created_at > coalesce(
              (select max(m3.created_at)
                 from public.mensagens m3
                where m3.denuncia_id = d.id
                  and m3.remetente = 'comissao'),
              '-infinity'::timestamptz
            )
      ) as por_responder,
      (select m4.conteudo
         from public.mensagens m4
        where m4.denuncia_id = d.id
        order by m4.created_at desc
        limit 1
      ) as ultima_conteudo,
      (select m5.created_at
         from public.mensagens m5
        where m5.denuncia_id = d.id
        order by m5.created_at desc
        limit 1
      ) as ultima_data,
      (select m6.remetente
         from public.mensagens m6
        where m6.denuncia_id = d.id
        order by m6.created_at desc
        limit 1
      ) as ultima_remetente
    from public.mensagens m
    where m.denuncia_id = d.id
  ) msg on true
  where case
          when public.is_super_admin()
            then p_faculdade is null or d.faculdade = p_faculdade
          else d.faculdade = public.current_user_faculdade()
               and (
                 public.current_user_polo() is null
                 or d.polo_id = public.current_user_polo()
               )
        end
  order by (msg.ultima_data) desc nulls last, d.created_at desc;
end;
$$;
