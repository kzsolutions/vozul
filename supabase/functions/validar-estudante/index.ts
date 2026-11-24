// ============================================================================
// Edge Function: validar-estudante
//
// Valida o numero de estudante contra o registo academico da Universidade
// Licungo (Quelimane e Beira) em tempo real durante o registo da conta.
//
// CONTRATO (POST /functions/v1/validar-estudante)
//   Request  : { "numero": "05.1234.5678", "instituicao": "licungo",
//                "polo": "licungo-quelimane" }
//   Response : { "valido": true, "estado": "activo", "nome": "...",
//                "faculdade": "...", "curso": "...",
//                "origem": "live" | "mock", "mensagem": "..." }
//
// MODO
//   A Universidade Licungo ainda nao disponibiliza API publica. Enquanto o
//   segredo LICUNGO_API_URL nao estiver definido, a funcao corre em "mock":
//   valida o formato e devolve um resultado deterministico, permitindo testar
//   todo o fluxo. Assim que a Universidade disponibilizar o endpoint do SIG,
//   basta definir os segredos e a funcao passa a usar a fonte real.
//
//   Segredos (Supabase -> Edge Functions -> Secrets):
//     LICUNGO_API_URL       endpoint do SIG, ex.: https://sig.ul.ac.mz/api/v1
//     LICUNGO_API_KEY       credencial (nunca va no cliente)
//     VALIDACAO_TIMEOUT_MS  timeout da chamada (opcional, omissao 5000)
//
// SEGURANCA / PRIVACIDADE
//   - verify_jwt = false porque o registo acontece ANTES de existir sessao.
//     A protecao real e a do corpo: so se aceitam numeros no formato oficial
//     e so se leem instituicao/polo de listas publicas da base de dados.
//   - Minimizacao de dados: guarda-se apenas nome, curso e estado. Nenhum
//     documento de identificacao, data de nascimento ou contacto.
//   - A chave da Universidade vive apenas nos segredos do servidor.
//   - Cache de 24 h evita bater na fonte academica a cada tentativa.
//   - O perfil do estudante NAO e escrito aqui: o trigger handle_new_user
//     herda instituicao/polo/estado a partir de 'validacoes_estudante'.
//     Assim o cliente nao consegue forjar uma validacao, mesmo que manipule
//     os metadados do signUp.
//   - No modo mock a faculdade e o curso vem do catalogo publicado para o polo
//     pedido (tabelas 'faculdades' e 'cursos'): a simulacao nunca inventa um
//     curso que nao exista na lista oficial da delegacao escolhida.
// ============================================================================

import { createClient } from 'jsr:@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

// Formato oficial do numero de estudante: 00.0000.0000
const FORMATO_NUMERO = /^[0-9]{2}\.[0-9]{4}\.[0-9]{4}$/

const TIMEOUT_PADRAO_MS = 5000
const CACHE_HORAS = 24
const MAX_TENTATIVAS_POR_MINUTO = 10

// ---------------------------------------------------------------------------
// Utilitarios
// ---------------------------------------------------------------------------

function responder(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    },
  })
}

function normalizarNumero(valor: unknown): string {
  return String(valor ?? '').trim().toUpperCase()
}

// Remove acentos e pontuacao para comparar nomes de forma tolerante
function normalizarNome(valor: unknown): string {
  return String(valor ?? '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/\s+/g, ' ')
    .trim()
    .toUpperCase()
}

function comTimeout<T>(promessa: Promise<T>, ms: number): Promise<T> {
  return Promise.race([
    promessa,
    new Promise<never>((_, rejeitar) =>
      setTimeout(() => rejeitar(new Error('timeout')), ms),
    ),
  ])
}

// ---------------------------------------------------------------------------
// Catalogo de faculdades e cursos
// ---------------------------------------------------------------------------

/**
 * Carrega os pares faculdade/curso publicados para um polo.
 *
 * A lista e ordenada para que a escolha do mock (por indice) seja estavel entre
 * chamadas: sem polo, ou sem lista publicada, devolve array vazio e o mock
 * omite faculdade/curso em vez de inventar valores.
 */
async function carregarCatalogo(
  supabase: ReturnType<typeof createClient>,
  poloId: string,
): Promise<CursoCatalogo[]> {
  if (!poloId) return []

  const { data, error } = await supabase
    .from('faculdades')
    .select('nome, cursos(nome)')
    .eq('polo_id', poloId)
    .eq('activo', true)
    .order('nome')

  if (error || !data?.length) {
    console.error('validar-estudante: catalogo indisponivel', error?.message ?? '')
    return []
  }

  return data
    .flatMap((f) =>
      (f.cursos ?? [])
        .filter((c) => c.nome)
        .map((c) => ({ faculdade: f.nome as string, curso: c.nome as string })),
    )
    .sort((a, b) =>
      a.faculdade === b.faculdade
        ? a.curso.localeCompare(b.curso, 'pt')
        : a.faculdade.localeCompare(b.faculdade, 'pt'),
    )
}

// ---------------------------------------------------------------------------
// Adaptadores por instituicao
//
// Cada instituicao tem o seu conector. A UniLicungo (instituicao "licungo")
// usa o mesmo endpoint para todos os polos, mas o resultado pode diferir
// (ex.: um aluno da Beira so existe no SIG da Beira). Um adaptador externo
// (tipo_conector = "externa") recebera o seu proprio endpoint no futuro.
// ---------------------------------------------------------------------------

interface ResultadoValidacao {
  valido: boolean
  estado: string | null
  nome: string | null
  faculdade: string | null
  curso: string | null
  origem: 'live' | 'mock'
  mensagem: string
  respostaFonte?: unknown
  motivoRecusa?: string
}

interface ContextoConsulta {
  numero: string
  poloId: string
  poloNome: string
  timeoutMs: number
  /** Faculdade e curso publicados para o polo indicado. */
  catalogo: CursoCatalogo[]
}

/** Par faculdade/curso publicado no catalogo de um polo. */
interface CursoCatalogo {
  faculdade: string
  curso: string
}

type Adaptador = (ctx: ContextoConsulta) => Promise<ResultadoValidacao>

// --- Adaptador mock (enquanto a Universidade nao expor API) -----------------
// Deterministico: o mesmo numero devolve sempre o mesmo resultado, para que
// os testes sejam reproduziveis. Nao corresponde a nenhum aluno real.
//
// A faculdade e o curso NAO sao inventados: sao lidos do catalogo oficial do
// polo pedido, que vive na base de dados. Assim o que o dispositivo mostra no
// registo pertence sempre a lista real da faculdade escolhida.
const validarMock: Adaptador = async (ctx) => {
  // Modo de teste: aceita qualquer numero no formato oficial enquanto a API
  // real da Universidade nao estiver integrada.
  const valido = true
  if (!valido) return { valido: false, estado: 'nao_encontrado', nome: null, faculdade: null, curso: null, origem: 'mock', mensagem: '' }
  }

  // Escolha estavel: os tres ultimos digitos do numero escolhem o par
  // faculdade/curso, de modo que numeros diferentes caem em cursos diferentes
  // e o mesmo numero repete sempre o mesmo resultado.
  const digitos = ctx.numero.replace(/\D/g, '')
  const escolhido = ctx.catalogo.length === 0
    ? null
    : ctx.catalogo[parseInt(digitos.slice(-3), 10) % ctx.catalogo.length]

  return {
    valido: true,
    estado: 'activo',
    nome: 'ESTUDANTE DE TESTE',
    faculdade: escolhido?.faculdade ?? null,
    curso: escolhido?.curso ?? null,
    origem: 'mock',
    mensagem: 'Número validado (modo de simulação).',
  }
}

// --- Adaptador live (SIG da Universidade) ----------------------------------
// Contrato esperado da Universidade (a confirmar com o SIG):
//   GET {LICUNGO_API_URL}/estudantes/{numero}
//   Header: Authorization: Bearer {LICUNGO_API_KEY}
//   Resposta 200: { "activo": true, "nome": "...", "faculdade": "...",
//                  "curso": "...", "polo": "quelimane" | "beira" }
const validarLiveLicungo: Adaptador = async (ctx) => {
  const base = Deno.env.get('LICUNGO_API_URL')!.replace(/\/+$/, '')
  const chave = Deno.env.get('LICUNGO_API_KEY')!

  const url = `${base}/estudantes/${encodeURIComponent(ctx.numero)}`

  const resposta = await comTimeout(
    fetch(url, {
      headers: {
        Authorization: `Bearer ${chave}`,
        Accept: 'application/json',
      },
    }),
    ctx.timeoutMs,
  )

  if (resposta.status === 404) {
    return {
      valido: false,
      estado: 'nao_encontrado',
      nome: null,
      faculdade: null,
      curso: null,
      origem: 'live',
      mensagem:
        'Número de estudante não encontrado no registo académico da universidade.',
      motivoRecusa: 'nao_encontrado',
    }
  }

  if (!resposta.ok) {
    throw new Error(`fonte_http_${resposta.status}`)
  }

  const corpo = await resposta.json()

  const activo = Boolean(corpo.activo ?? corpo.estado === 'activo')

  if (!activo) {
    return {
      valido: false,
      estado: String(corpo.estado ?? 'inactivo'),
      nome: normalizarNome(corpo.nome) || null,
      faculdade: corpo.faculdade ?? null,
      curso: corpo.curso ?? null,
      origem: 'live',
      mensagem:
        'O estado do aluno na universidade não permite o registo (inativo, formado ou com matrícula suspensa).',
      motivoRecusa: 'aluno_nao_ativo',
      respostaFonte: corpo,
    }
  }

  return {
    valido: true,
    estado: String(corpo.estado ?? 'activo'),
    nome: normalizarNome(corpo.nome) || null,
    faculdade: corpo.faculdade ?? null,
    curso: corpo.curso ?? null,
    origem: 'live',
    mensagem: 'Número validado no registo académico da universidade.',
    respostaFonte: corpo,
  }
}

function obterAdaptador(tipoConector: string): Adaptador {
  switch (tipoConector) {
    case 'licungo':
      // Sem endpoint configurado, cai no mock para permitir os testes.
      return Deno.env.get('LICUNGO_API_URL') ? validarLiveLicungo : validarMock
    default:
      return validarMock
  }
}

// ---------------------------------------------------------------------------
// Rate limit simples em memoria (por IP)
// ---------------------------------------------------------------------------
const tentativas = new Map<string, { count: number; desde: number }>()

function excedeuLimite(ip: string): boolean {
  const agora = Date.now()
  const registo = tentativas.get(ip)

  if (!registo || agora - registo.desde > 60_000) {
    tentativas.set(ip, { count: 1, desde: agora })
    return false
  }

  registo.count += 1
  return registo.count > MAX_TENTATIVAS_POR_MINUTO
}

// ---------------------------------------------------------------------------
// Handler
// ---------------------------------------------------------------------------
Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return responder({})

  if (req.method !== 'POST') {
    return responder({ erro: 'Método não permitido. Use POST.' }, 405)
  }

  const ip =
    req.headers.get('x-forwarded-for')?.split(',')[0].trim() ?? 'desconhecido'

  if (excedeuLimite(ip)) {
    return responder(
      {
        erro: 'Demasiadas tentativas. Aguarde um minuto e tente novamente.',
      },
      429,
    )
  }

  let corpo: Record<string, unknown>
  try {
    corpo = await req.json()
  } catch {
    return responder({ erro: 'Corpo do pedido inválido (JSON).' }, 400)
  }

  const numero = normalizarNumero(corpo.numero)
  const instituicaoId = String(corpo.instituicao ?? 'licungo').trim()
  const poloId = String(corpo.polo ?? '').trim()

  // ---- Validacao do formato (antes de qualquer consulta) ------------------
  if (!FORMATO_NUMERO.test(numero)) {
    return responder({
      valido: false,
      erro: 'Formato inválido. Use o formato 00.0000.0000.',
    }, 400)
  }

  // ---- Instituicao e polo: so valores publicados na base de dados ---------
  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

  const { data: instituicao, error: erroInst } = await supabase
    .from('instituicoes')
    .select('id, nome, sigla, tipo_conector, activo')
    .eq('id', instituicaoId)
    .eq('activo', true)
    .maybeSingle()

  if (erroInst || !instituicao) {
    return responder(
      { valido: false, erro: 'Instituição de ensino não reconhecida.' },
      400,
    )
  }

  let polo: { id: string; nome: string; cidade: string } | null = null
  if (poloId) {
    const { data: dadosPolo } = await supabase
      .from('polos')
      .select('id, nome, cidade, activo')
      .eq('id', poloId)
      .eq('instituicao_id', instituicaoId)
      .eq('activo', true)
      .maybeSingle()

    if (dadosPolo) polo = dadosPolo
  }

  // Sem polo indicado, o agrupamento fica para inferencia da fonte. O polo
  // serve apenas para efeitos de registo; o que decide a validade e sempre
  // o numero de estudante.
  const timeoutMs = Number(Deno.env.get('VALIDACAO_TIMEOUT_MS') ?? TIMEOUT_PADRAO_MS)
  const adaptador = obterAdaptador(instituicao.tipo_conector)

  // ---- Catalogo oficial do polo (faculdades e cursos publicados) ------------
  // E a fonte de verdade das listas: o mock devolve sempre um par que existe
  // no catalogo do polo pedido, nunca um valor inventado.
  const catalogo = await carregarCatalogo(supabase, polo?.id ?? '')

  // ---- Cache valido (24 h) evita chamar a fonte a cada tentativa ----------
  // O cache e separado por polo: o mesmo numero validado para a Beira nao pode
  // servir a resposta da Beira a quem se registou em Quelimane, porque o perfil
  // herda o polo da validacao.
  let consultaCache = supabase
    .from('validacoes_estudante')
    .select('*')
    .eq('numero_estudante', numero)
    .eq('instituicao_id', instituicao.id)
    .gt('expira_em', new Date().toISOString())
    .order('validado_em', { ascending: false })
    .limit(1)

  consultaCache = polo
    ? consultaCache.eq('polo_id', polo.id)
    : consultaCache.is('polo_id', null)

  const { data: emCache } = await consultaCache.maybeSingle()

  if (emCache) {
    return responder({
      valido: emCache.valido,
      estado: emCache.estado_aluno,
      nome: emCache.nome_normalizado,
      faculdade: emCache.faculdade,
      curso: emCache.curso,
      origem: emCache.origem,
      polo: polo?.nome ?? null,
      mensagem: emCache.valido
        ? 'Número validado (cache).'
        : 'Número não encontrado no registo académico.',
      cache: true,
    })
  }

  // ---- Consulta a fonte ---------------------------------------------------
  let resultado: ResultadoValidacao
  try {
    resultado = await adaptador({
      numero,
      poloId: polo?.id ?? '',
      poloNome: polo?.nome ?? 'polo por inferir',
      timeoutMs,
      catalogo,
    })
  } catch (erro) {
    const msg = String((erro as Error)?.message ?? erro)
    const excedeuTempo = msg === 'timeout'
    console.error('validar-estudante: falha na fonte', msg)

    // Falha da fonte NAO significa numero invalido: devolve-se "indisponivel"
    // para que o registo fique pendente em vez de recusar o aluno.
    return responder(
      {
        valido: null,
        erro: 'indisponivel',
        mensagem: excedeuTempo
          ? 'O sistema da universidade demorou a responder. Tente novamente em instantes.'
          : 'O sistema da universidade está temporariamente indisponível. Tente novamente mais tarde.',
      },
      503,
    )
  }

  // ---- Regista a validacao (cache + auditoria) ---------------------------
  const { data: registo } = await supabase.rpc('registar_validacao_estudante', {
    p_numero: numero,
    p_instituicao_id: instituicao.id,
    p_polo_id: polo?.id ?? null,
    p_valido: resultado.valido,
    p_estado_aluno: resultado.estado,
    p_nome_normalizado: resultado.nome,
    p_curso: resultado.curso,
    p_faculdade: resultado.faculdade,
    p_origem: resultado.origem,
    p_resposta_fonte: resultado.respostaFonte ?? null,
    p_motivo_recusa: resultado.motivoRecusa ?? null,
    p_validade_horas: resultado.valido ? CACHE_HORAS : 1,
  })

  return responder({
    valido: resultado.valido,
    estado: resultado.estado,
    nome: resultado.nome,
    faculdade: resultado.faculdade,
    curso: resultado.curso,
    origem: resultado.origem,
    instituicao: instituicao.sigla,
    polo: polo?.nome ?? null,
    mensagem: resultado.mensagem,
    validado_em: registo?.validado_em ?? new Date().toISOString(),
  })
})