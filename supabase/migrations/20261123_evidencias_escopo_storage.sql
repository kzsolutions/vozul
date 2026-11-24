-- O criador da denúncia já fica registado em participantes_denuncia, mesmo
-- quando a denúncia é anónima. A janela de 24h permitia a qualquer utilizador
-- autenticado ler/anexar provas de uma denúncia anónima apenas por adivinhar o id.
create or replace function public.pode_anexar_evidencia(p_denuncia bigint)
returns boolean
language sql
stable
security definer
set search_path to 'public'
as $function$
  select exists (
    select 1
    from public.denuncias d
    where d.id = p_denuncia
      and (
        d.estudante_id = auth.uid()
        or exists (
          select 1
          from public.participantes_denuncia p
          where p.denuncia_id = d.id
            and p.usuario_id = auth.uid()
        )
      )
  );
$function$;

-- A leitura em storage passa a respeitar o mesmo escopo da tabela de provas.
drop policy if exists "acesso_evidencias" on storage.objects;

create policy "acesso_evidencias"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'denuncias'
  and exists (
    select 1
    from public.denuncias_evidencias e
    where e.file_url = storage.objects.name
  )
);
