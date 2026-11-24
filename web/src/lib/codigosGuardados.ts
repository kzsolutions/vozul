const LEGADO = 'vozul_codigos_denuncia'
const PREFIXO = 'codigos_guardados_'

function chave(userId: string): string {
  return PREFIXO + userId
}

function normalizar(codigo: string): string {
  return codigo.trim().toUpperCase()
}

function lerLista(chaveAlvo: string): string[] {
  try {
    const bruto = JSON.parse(localStorage.getItem(chaveAlvo) || '[]')
    if (!Array.isArray(bruto)) return []
    return bruto.map((item) => normalizar(typeof item === 'string' ? item : item?.codigo ?? '')).filter(Boolean)
  } catch {
    return []
  }
}

function escrever(userId: string, lista: string[]) {
  localStorage.setItem(chave(userId), JSON.stringify(lista))
}

export function carregarCodigos(userId: string): string[] {
  const lista = lerLista(chave(userId))

  try {
    const bruto = localStorage.getItem(LEGADO)
    if (bruto) {
      const legado = JSON.parse(bruto)
      if (Array.isArray(legado)) {
        for (const item of legado) {
          const codigo = normalizar(typeof item === 'string' ? item : item?.codigo ?? '')
          if (codigo && !lista.includes(codigo)) lista.unshift(codigo)
        }
      }
      if (lista.length) escrever(userId, lista)
      localStorage.removeItem(LEGADO)
    }
  } catch {
    localStorage.removeItem(LEGADO)
  }

  return lista
}

export function guardarCodigo(userId: string, codigo: string): string[] {
  const normalizado = normalizar(codigo)
  const lista = lerLista(chave(userId))
  if (normalizado && !lista.includes(normalizado)) {
    lista.unshift(normalizado)
    escrever(userId, lista.slice(0, 50))
  }
  return lista
}

export function removerCodigo(userId: string, codigo: string): string[] {
  const normalizado = normalizar(codigo)
  const lista = lerLista(chave(userId)).filter((c) => c !== normalizado)
  escrever(userId, lista)
  return lista
}
