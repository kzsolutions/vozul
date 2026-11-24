import { createClient } from '@supabase/supabase-js'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const CHAVE = new TextEncoder().encode(SERVICE_ROLE_KEY)
const TTL_SEGUNDOS = 120

const ORIGENS_EXPLICITAS = new Set(
  (Deno.env.get('AUTH_HANDOFF_ORIGINS') ?? '')
    .split(',')
    .map((origem) => origem.trim())
    .filter(Boolean),
)

function origemAutorizada(origem: string): boolean {
  if (ORIGENS_EXPLICITAS.has(origem)) return true
  try {
    const url = new URL(origem)
    if (url.hostname === 'localhost' || url.hostname === '127.0.0.1') return true
    return url.protocol === 'https:' && url.hostname.endsWith('.vercel.app')
  } catch {
    return false
  }
}

const CABECALHES_PERMITIDOS = [
  'authorization',
  'x-client-info',
  'apikey',
  'content-type',
  'x-retry-count',
  'traceparent',
  'tracestate',
  'baggage',
  'x-region',
].join(', ')

const METODOS_PERMITIDOS = 'GET, POST, PUT, PATCH, DELETE, OPTIONS'

function b64u(bytes: Uint8Array): string {
  let binario = ''
  for (const byte of bytes) binario += String.fromCharCode(byte)
  return btoa(binario).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
}

function unb64u(valor: string): Uint8Array {
  const normalizado = valor.replace(/-/g, '+').replace(/_/g, '/')
  const preenchimento = normalizado.length % 4 === 0 ? '' : '='.repeat(4 - (normalizado.length % 4))
  const binario = atob(normalizado + preenchimento)
  return Uint8Array.from(binario, (caractere) => caractere.charCodeAt(0))
}

async function chaveCriptografia(): Promise<CryptoKey> {
  const digest = await crypto.subtle.digest('SHA-256', CHAVE)
  return crypto.subtle.importKey('raw', digest, { name: 'AES-GCM' }, false, ['encrypt', 'decrypt'])
}

async function cifrar(texto: string): Promise<string> {
  const iv = crypto.getRandomValues(new Uint8Array(12))
  const cifrado = await crypto.subtle.encrypt(
    { name: 'AES-GCM', iv },
    await chaveCriptografia(),
    new TextEncoder().encode(texto),
  )
  return `${b64u(iv)}.${b64u(new Uint8Array(cifrado))}`
}

async function decifrar(valor: string): Promise<{ id: string; user_id: string; access_token: string; refresh_token: string; exp: number }> {
  const partes = valor.split('.')
  if (partes.length !== 2) throw new Error('token_invalido')
  const claro = await crypto.subtle.decrypt(
    { name: 'AES-GCM', iv: unb64u(partes[0]) },
    await chaveCriptografia(),
    unb64u(partes[1]),
  )
  const dados = JSON.parse(new TextDecoder().decode(claro))
  if (
    !dados?.id ||
    !dados?.user_id ||
    !dados?.access_token ||
    !dados?.refresh_token ||
    typeof dados?.exp !== 'number'
  ) {
    throw new Error('token_invalido')
  }
  return dados
}

function responder(body: Record<string, unknown>, status = 200, headers: Record<string, string> = {}): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      ...headers,
    },
  })
}

async function criar(
  req: Request,
  corpo: Record<string, unknown>,
  supabase: ReturnType<typeof createClient>,
  cors: Record<string, string>,
): Promise<Response> {
  const accessToken = String(corpo.access_token ?? '').trim()
  const refreshToken = String(corpo.refresh_token ?? '').trim()
  const bearer = req.headers.get('authorization')?.match(/^Bearer (.+)$/i)?.[1] ?? ''

  if (!bearer || bearer !== accessToken || !refreshToken) {
    return responder({ erro: 'Sessão inválida para transferência.' }, 401, cors)
  }

  const { data: userData, error: userError } = await supabase.auth.getUser(bearer)
  if (userError || !userData.user) {
    return responder({ erro: 'Utilizador não autenticado.' }, 401, cors)
  }

  const { data: perfil, error: perfilError } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', userData.user.id)
    .maybeSingle()

  if (perfilError) {
    return responder({ erro: 'Não foi possível validar o perfil.' }, 500, cors)
  }
  if (!perfil || (perfil.role !== 'admin' && perfil.role !== 'super_admin')) {
    return responder({ erro: 'Acesso restrito a administradores.' }, 403, cors)
  }

  const id = crypto.randomUUID()
  const agoraSegundos = Math.floor(Date.now() / 1000)
  const exp = agoraSegundos + TTL_SEGUNDOS
  const cifrado = await cifrar(JSON.stringify({
    id,
    user_id: userData.user.id,
    access_token: accessToken,
    refresh_token: refreshToken,
    exp,
  }))
  const token = `${b64u(new TextEncoder().encode(id))}.${cifrado}`

  const { error } = await supabase
    .from('auth_handoffs')
    .insert({
      id,
      user_id: userData.user.id,
      expires_at: new Date(exp * 1000).toISOString(),
    })

  if (error) {
    return responder({ erro: 'Não foi possível criar a transferência.' }, 500, cors)
  }

  await supabase
    .from('auth_handoffs')
    .delete()
    .lt('expires_at', new Date(Date.now() - 86_400_000).toISOString())

  return responder({ token, expira_em: exp }, 200, cors)
}

async function trocar(
  corpo: Record<string, unknown>,
  supabase: ReturnType<typeof createClient>,
  cors: Record<string, string>,
): Promise<Response> {
  const token = String(corpo.token ?? '').trim()
  if (!token || token.length > 4096) {
    return responder({ erro: 'Código de transferência inválido.' }, 400, cors)
  }

  const partes = token.split('.')
  if (partes.length !== 3) {
    return responder({ erro: 'Código de transferência inválido.' }, 400, cors)
  }

  let dados: Awaited<ReturnType<typeof decifrar>>
  let id: string
  try {
    id = new TextDecoder().decode(unb64u(partes[0]))
    if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(id)) {
      throw new Error('token_invalido')
    }
    dados = await decifrar(`${partes[1]}.${partes[2]}`)
  } catch {
    return responder({ erro: 'Código de transferência inválido.' }, 400, cors)
  }

  if (dados.id !== id || dados.exp < Math.floor(Date.now() / 1000)) {
    return responder({ erro: 'Código de transferência expirado.' }, 410, cors)
  }

  const { data, error } = await supabase
    .from('auth_handoffs')
    .update({ consumido_em: new Date().toISOString() })
    .eq('id', id)
    .is('consumido_em', null)
    .gt('expires_at', new Date().toISOString())
    .select('id, user_id')
    .maybeSingle()

  if (error) {
    return responder({ erro: 'Não foi possível validar a transferência.' }, 500, cors)
  }
  if (!data || data.user_id !== dados.user_id) {
    return responder({ erro: 'Código de transferência inválido ou já utilizado.' }, 410, cors)
  }

  return responder({
    access_token: dados.access_token,
    refresh_token: dados.refresh_token,
    user_id: dados.user_id,
  }, 200, cors)
}

Deno.serve(async (req: Request) => {
  const origem = req.headers.get('origin')
  if (origem && !origemAutorizada(origem)) {
    return responder({ erro: 'Origem não autorizada.' }, 403)
  }

  const cors: Record<string, string> = {
    'Access-Control-Allow-Origin': origem ?? '*',
    'Access-Control-Allow-Headers': CABECALHES_PERMITIDOS,
    'Access-Control-Allow-Methods': METODOS_PERMITIDOS,
    'Access-Control-Max-Age': '86400',
    Vary: 'Origin',
  }

  try {
    if (req.method === 'OPTIONS') return responder({}, 200, cors)
    if (req.method !== 'POST') {
      return responder({ erro: 'Método não permitido. Use POST.' }, 405, cors)
    }

    let corpo: Record<string, unknown>
    try {
      corpo = await req.json()
    } catch {
      return responder({ erro: 'Corpo do pedido inválido (JSON).' }, 400, cors)
    }

    const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
      auth: { persistSession: false, autoRefreshToken: false },
    })

    switch (String(corpo.acao ?? '').trim()) {
      case 'criar':
        return criar(req, corpo, supabase, cors)
      case 'trocar':
        return trocar(corpo, supabase, cors)
      default:
        return responder({ erro: 'Ação inválida. Use "criar" ou "trocar".' }, 400, cors)
    }
  } catch (erro) {
    console.error('auth-handoff: erro interno', erro)
    return responder({ erro: 'Erro interno na transferência.' }, 500, cors)
  }
})
