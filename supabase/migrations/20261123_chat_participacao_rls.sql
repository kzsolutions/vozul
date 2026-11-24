-- Permite que o estudante autenticado leia a sua própria participação.
-- Sem esta política, os subqueries das políticas de `mensagens` não encontram
-- a participação criada por `participar_denuncia` e a RLS nega o chat.
drop policy if exists "estudante_ve_sua_participacao" on public.participantes_denuncia;

create policy "estudante_ve_sua_participacao"
on public.participantes_denuncia
for select
to authenticated
using (usuario_id = auth.uid());
