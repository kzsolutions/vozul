-- Âmbito dos administradores de nível 2 (1/3): colunas e validação do catálogo.
--
-- O administrador fica preso à faculdade E à delegação indicadas na criação.
-- O nome da faculdade continua a ser a chave usada pelas denúncias; o id
-- garante integridade referencial com o catálogo.

alter table public.profiles
  add column if not exists faculdade_id text
  references public.faculdades(id) on delete set null;

-- Preencher o âmbito dos administradores existentes, apenas quando o nome da
-- faculdade identifica um único pólo.
update public.profiles p
   set polo_id = f.polo_id
  from public.faculdades f
 where p.role = 'admin'
   and p.polo_id is null
   and p.faculdade is not null
   and f.nome = p.faculdade
   and (select count(*) from public.faculdades f2 where f2.nome = p.faculdade) = 1;

update public.profiles p
   set faculdade_id = f.id
  from public.faculdades f
 where p.faculdade_id is null
   and p.faculdade is not null
   and f.nome = p.faculdade
   and (p.polo_id is null or f.polo_id = p.polo_id);

-- Delegação do utilizador autenticado.
create or replace function public.current_user_polo()
returns text
language sql
stable
security definer
set search_path = 'public'
as $$
  select polo_id from public.profiles where id = auth.uid();
$$;

-- Manter faculdade_id derivado do catálogo e coerente com o pólo.
create or replace function public.validar_catalogo_academico()
returns trigger
language plpgsql
set search_path = 'public'
as $$
declare
  v_polo   text := btrim(coalesce(new.polo_id, ''));
  v_fac    text := btrim(coalesce(new.faculdade, ''));
  v_cur    text := btrim(coalesce(new.curso, ''));
  v_fac_id text;
begin
  if v_polo = '' then
    if tg_table_name = 'profiles' then
      new.faculdade_id := null;
    end if;
    return new;
  end if;

  select f.id into v_fac_id
    from public.faculdades f
   where f.polo_id = v_polo
     and f.activo
     and f.nome = v_fac
   limit 1;

  if v_fac = '' or v_fac_id is null then
    raise exception
      'A faculdade indicada nao pertence ao campus seleccionado: %', v_fac
      using errcode = '23514';
  end if;

  if v_cur <> '' and not exists (
       select 1
         from public.cursos c
         join public.faculdades f on f.id = c.faculdade_id
        where f.polo_id = v_polo
          and f.nome = v_fac
          and c.activo
          and c.nome = v_cur
  ) then
    raise exception
      'O curso indicado nao pertence a faculdade seleccionada no campus: %', v_cur
      using errcode = '23514';
  end if;

  if tg_table_name = 'profiles' then
    new.faculdade_id := v_fac_id;
  end if;

  return new;
end;
$$;
