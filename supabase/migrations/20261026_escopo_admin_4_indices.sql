-- As políticas de escopo filtram perfis por delegação e faculdade:
-- sem índices, cada leitura de denúncia faz uma varredura em profiles.
create index if not exists idx_profiles_polo
  on public.profiles (polo_id);

create index if not exists idx_profiles_faculdade_id
  on public.profiles (faculdade_id);
