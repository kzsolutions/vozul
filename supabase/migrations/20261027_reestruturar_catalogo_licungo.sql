-- Reestruturação do catálogo Licungo conforme edital 2027
-- Mantém IDs existentes quando possível. Cria polo EaD separado. Faz mapeamentos históricos.

begin;

-- 1) Polos
insert into public.polos (id, instituicao_id, nome, cidade, activo, principal)
values ('licungo-ead', 'licungo', 'Cursos de Ensino à Distância (EaD)', 'Quelimane/Beira', true, false)
on conflict (id) do update set
  nome = excluded.nome,
  cidade = excluded.cidade,
  activo = excluded.activo,
  principal = excluded.principal;

-- 2) Novas faculdades
insert into public.faculdades (id, instituicao_id, polo_id, nome, activo, provisorio)
values
  ('quelimane-ciencias-sociais', 'licungo', 'licungo-quelimane', 'Faculdade de Ciências Sociais', true, false),
  ('beira-psicologia-ciencias-educacao', 'licungo', 'licungo-beira', 'Faculdade de Psicologia e Ciências da Educação', true, false),
  ('beira-ciencias-empresariais-juridicas', 'licungo', 'licungo-beira', 'Faculdade de Ciências Empresariais e Jurídicas', true, false),
  ('ead-centro', 'licungo', 'licungo-ead', 'Centro / Unidade de Ensino à Distância (EaD)', true, false)
on conflict (id) do update set
  nome = excluded.nome,
  polo_id = excluded.polo_id,
  activo = excluded.activo;

-- 3) Mover cursos mantendo IDs existentes quando aplicável
-- Quelimane: Letras/Humanidades -> Ciências Sociais
update public.cursos set faculdade_id = 'quelimane-ciencias-sociais'
where id in ('que-lh-direito', 'que-lh-filosofia-social', 'que-lh-sociologia');

-- Quelimane: Psicologia Social e das Organizações vem da Educação
update public.cursos set faculdade_id = 'quelimane-ciencias-sociais'
where id = 'que-ed-psicologia-social';

-- Beira: Economia/Gestão -> Ciências Empresariais e Jurídicas
update public.cursos set faculdade_id = 'beira-ciencias-empresariais-juridicas'
where id in ('beira-eg-contabilidade-financas', 'beira-eg-gestao-empresas', 'beira-eg-recursos-humanos');

-- Beira: Direito vem de Letras/Humanidades
update public.cursos set faculdade_id = 'beira-ciencias-empresariais-juridicas'
where id = 'beira-lh-direito';

-- Beira: maior parte da Educação -> Psicologia e Ciências da Educação
update public.cursos set faculdade_id = 'beira-psicologia-ciencias-educacao'
where faculdade_id = 'beira-educacao';

-- 4) Criar cursos EaD (novos IDs)
insert into public.cursos (id, faculdade_id, nome, activo)
values
  ('ead-age', 'ead-centro', 'Administração e Gestão Educacional', true),
  ('ead-ensino-basico', 'ead-centro', 'Ensino Básico', true),
  ('ead-ensino-biologia', 'ead-centro', 'Ensino de Biologia', true),
  ('ead-ensino-ingles', 'ead-centro', 'Ensino de Inglês', true),
  ('ead-ensino-portugues', 'ead-centro', 'Ensino de Português', true)
on conflict (id) do update set nome = excluded.nome, activo = excluded.activo, faculdade_id = excluded.faculdade_id;

-- 5) Atualizar histórico de denúncias (campo texto) com mapeamento
update public.denuncias d
set faculdade = case
  when d.polo_id = 'licungo-quelimane' and d.faculdade = 'Faculdade de Letras e Humanidades' then 'Faculdade de Ciências Sociais'
  when d.polo_id = 'licungo-beira' and d.faculdade = 'Faculdade de Educação' then 'Faculdade de Psicologia e Ciências da Educação'
  when d.polo_id = 'licungo-beira' and d.faculdade = 'Faculdade de Economia e Gestão' then 'Faculdade de Ciências Empresariais e Jurídicas'
  when d.polo_id = 'licungo-beira' and d.faculdade = 'Faculdade de Letras e Humanidades' and exists (select 1 from public.cursos c where c.id = d.curso and c.nome = 'Direito') then 'Faculdade de Ciências Empresariais e Jurídicas'
  else d.faculdade
end;

-- 6) Atualizar perfis com nova faculdade_id onde possível
update public.profiles p
set faculdade_id = f.id,
    faculdade = f.nome
from public.faculdades f
where f.polo_id = p.polo_id
  and (
    (p.faculdade = 'Faculdade de Letras e Humanidades' and p.polo_id = 'licungo-quelimane') or
    (p.faculdade = 'Faculdade de Educação' and p.polo_id = 'licungo-beira') or
    (p.faculdade = 'Faculdade de Economia e Gestão' and p.polo_id = 'licungo-beira')
  )
  and f.id in ('quelimane-ciencias-sociais','beira-psicologia-ciencias-educacao','beira-ciencias-empresariais-juridicas');

-- 7) Desativar faculdades que ficaram vazias ou obsoletas quando sem dependências
update public.faculdades f
set activo = false
where f.id in ('beira-educacao','beira-economia-gestao')
  and not exists (select 1 from public.cursos c where c.faculdade_id = f.id and c.activo = true)
  and not exists (select 1 from public.denuncias d where d.faculdade = f.nome and d.polo_id = f.polo_id)
  and not exists (select 1 from public.profiles p where p.faculdade = f.nome and p.polo_id = f.polo_id);

commit;
