-- ============================================================================
-- Catalogos por campus: denuncia e validacao posterior
--
-- 1) public.criar_denuncia passa a receber o campus (polo_id).
--    A denuncia e registada no campus onde o estudante frequenta, e o trigger
--    validar_catalogo_academico passa a garantir que faculdade/curso
--    pertencem a esse campus.
--
-- 2) public.aplicar_validacao_perfil passa a receber o campus.
--    Necessario para quem criou a conta com a fonte academica indisponivel:
--    nesse caso o perfil ficou sem polo, e sem ele a validacao aplicada nao
--    sabe de que campus e a faculdade/curso que vai para o perfil.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1) criar_denuncia com campus
--
-- A assinatura muda (parametro novo), por isso a versao anterior e removida:
-- com duas versoes em overload o PostgREST deixa de saber qual chamar quando
-- o cliente nao envia todos os parametros.
-- ---------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.criar_denuncia(
  text, text, text, text, text, text, text, text, text, text,
  date, boolean, uuid, boolean, text
);

CREATE OR REPLACE FUNCTION public.criar_denuncia(
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
  email_notificacao text DEFAULT NULL::text,
  p_polo_id text DEFAULT NULL::text
)
 RETURNS public.denuncias
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
    public.obter_admin_faculdade(faculdade)
  )
  returning * into nova;

  if auth.uid() is not null then
    insert into public.participantes_denuncia (denuncia_id, usuario_id)
    values (nova.id, auth.uid())
    on conflict (denuncia_id, usuario_id) do nothing;
  end if;

  return nova;
end;
$function$;

COMMENT ON FUNCTION public.criar_denuncia(
  text, text, text, text, text, text, text, text, text, text,
  date, boolean, uuid, boolean, text, text
) IS
  'Regista uma denuncia. p_polo_id indica o campus e, quando enviado, o '
  'trigger validar_catalogo_academico exige que faculdade/curso pertencam a esse campus.';

-- ---------------------------------------------------------------------------
-- 2) aplicar_validacao_perfil com campus
--
-- A validacao oficial e procurada primeiro no campus pedido: uma pessoa pode
-- ter mais do que um numero registado (papeis diferentes na universidade) e so
-- o campus escolhido identifica a faculdade/curso correctos. Sem p_polo_id o
-- comportamento antigo e mantido (qualquer validacao valida, a mais recente).
-- ---------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.aplicar_validacao_perfil();

CREATE OR REPLACE FUNCTION public.aplicar_validacao_perfil(
  p_polo_id text DEFAULT NULL::text
)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_numero    text;
  v_validacao public.validacoes_estudante%ROWTYPE;
  v_polo      text := nullif(btrim(coalesce(p_polo_id, '')), '');
  v_user      uuid := auth.uid();
BEGIN
  IF v_user IS NULL THEN
    RAISE EXCEPTION 'Acesso negado: sessao necessaria' USING ERRCODE = '42501';
  END IF;

  IF NOT public.is_estudante() THEN
    RAISE EXCEPTION 'Apenas estudantes podem validar o numero' USING ERRCODE = '42501';
  END IF;

  SELECT numero_estudante INTO v_numero
  FROM public.profiles
  WHERE id = v_user;

  IF v_numero IS NULL OR v_numero = '' THEN
    RAISE EXCEPTION 'Perfil sem numero de estudante' USING ERRCODE = 'P0001';
  END IF;

  IF v_polo IS NOT NULL THEN
    -- Campus pedido: so uma validacao desse campus serve. Sem correspondencia
    -- devolvemos false em vez de aplicar a validacao de outro campus, que
    -- deixaria o perfil com uma faculdade que o estudante nao frequenta.
    SELECT * INTO v_validacao
    FROM public.validacoes_estudante
    WHERE numero_estudante = v_numero
      AND valido = true
      AND expira_em > now()
      AND polo_id = v_polo
    ORDER BY validado_em DESC
    LIMIT 1;
  ELSE
    SELECT * INTO v_validacao
    FROM public.validacoes_estudante
    WHERE numero_estudante = v_numero
      AND valido = true
      AND expira_em > now()
    ORDER BY validado_em DESC
    LIMIT 1;
  END IF;

  IF v_validacao.numero_estudante IS NULL THEN
    RETURN false;   -- ainda sem validacao valida: nada a aplicar
  END IF;

  UPDATE public.profiles
     set instituicao_id           = v_validacao.instituicao_id,
         polo_id                  = v_polo,
         numero_validado_em       = v_validacao.validado_em,
         numero_validado_origem   = v_validacao.origem,
         numero_validado_estado   = v_validacao.estado_aluno,
         faculdade                = COALESCE(v_validacao.faculdade, faculdade),
         curso                    = COALESCE(v_validacao.curso, curso),
         updated_at               = now()
   WHERE id = v_user;

  RETURN true;
END;
$function$;

COMMENT ON FUNCTION public.aplicar_validacao_perfil(text) IS
  'Aplica ao perfil a validacao oficial registada. p_polo_id restringe a busca '
  'ao campus escolhido pelo estudante; sem ele usa a validacao valida mais recente.';

-- ---------------------------------------------------------------------------
-- 3) Par faculdade/curso tem de ser coerente dentro do campus
--
-- A versao anterior aceitava um curso publicado no campus mas de outra
-- faculdade, o que deixava denuncias com pares incoerentes ("Faculdade de
-- Ciencias Agrarias / Direito"). Como a aplicacao so oferece o curso da
-- faculdade escolhida, a base de dados passa a exigir o mesmo.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.validar_catalogo_academico()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
DECLARE
  v_polo text := btrim(coalesce(NEW.polo_id, ''));
  v_fac  text := btrim(coalesce(NEW.faculdade, ''));
  v_cur  text := btrim(coalesce(NEW.curso, ''));
BEGIN
  -- Sem polo definido nao existe catalogo de referencia.
  IF v_polo = '' THEN
    RETURN NEW;
  END IF;

  IF v_fac = '' OR NOT EXISTS (
       select 1 from public.faculdades f
        where f.polo_id = v_polo and f.activo and f.nome = v_fac
  ) THEN
    RAISE EXCEPTION
      'A faculdade indicada nao pertence ao campus seleccionado: %', v_fac
      USING ERRCODE = '23514';
  END IF;

  IF v_cur <> '' AND NOT EXISTS (
       select 1
         from public.cursos c
         join public.faculdades f on f.id = c.faculdade_id
        where f.polo_id = v_polo
          and f.nome = v_fac
          and c.activo
          and c.nome = v_cur
  ) THEN
    RAISE EXCEPTION
      'O curso indicado nao pertence a faculdade seleccionada no campus: %', v_cur
      USING ERRCODE = '23514';
  END IF;

  RETURN NEW;
END;
$function$;