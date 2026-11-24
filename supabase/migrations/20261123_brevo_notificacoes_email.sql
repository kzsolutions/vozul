-- Parte B: notificações por email via Brevo (sem SMS).
--
-- Idempotente: pode ser repetido com segurança.
-- A entrega é feita pela edge function `enviar-notificacoes`, que lê
-- BREVO_API_KEY e BREVO_FROM dos secrets do projeto.
-- Já existem triggers de mudança de estado e de resposta da comissão;
-- estes não são alterados para evitar notificações duplicadas.

alter table public.notificacoes
  add column if not exists via_email boolean not null default false,
  add column if not exists via_sms boolean not null default false,
  add column if not exists detalhe_entrega text,
  add column if not exists enviado_externo_at timestamptz;

-- Nova denúncia: avisa super_admin e o admin da faculdade/polo.
create or replace function public.notificar_admins_nova_denuncia()
returns trigger
language plpgsql
security definer
set search_path = 'public'
as $$
begin
  insert into public.notificacoes
    (usuario_id, denuncia_id, titulo, conteudo, lida, via_sms, via_email)
  select p.id, new.id,
         'Nova denúncia ' || new.codigo,
         'Foi registada uma denúncia de "' ||
           coalesce(nullif(new.categoria_custom, ''), new.categoria) || '".',
         false, false, true
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

-- Nova mensagem: avisa os admins da faculdade/polo (excepto o autor).
-- A notificação ao estudante já é feita por
-- `notificar_estudante_nova_mensagem`, por isso não é duplicada aqui.
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

  insert into public.notificacoes
    (usuario_id, denuncia_id, titulo, conteudo, lida, via_sms, via_email)
  select p.id, new.denuncia_id,
         'Nova mensagem em ' || d.codigo,
         case
           when new.remetente = 'estudante'
             then 'O estudante enviou uma mensagem na denúncia "' ||
                  coalesce(nullif(d.categoria_custom, ''), d.categoria) || '".'
           else 'A comissão respondeu à denúncia "' ||
                coalesce(nullif(d.categoria_custom, ''), d.categoria) || '".'
         end,
         false, false, true
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

-- Notificações antigas por SMS ainda por entregar passam a email.
update public.notificacoes
   set via_sms = false, via_email = true
 where enviado_externo_at is null
   and via_sms
   and not via_email;
