-- A alteração de estado e de responsável passa a ser apenas de leitura
-- tanto no painel web como na app; nenhuma política de UPDATE permanece.
drop policy if exists "admin_atualiza_denuncias" on public.denuncias;
