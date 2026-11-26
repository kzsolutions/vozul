export function normalizarNumeroEstudante(n: string): string {
  return (n || '').trim()
}

export function formatarNumeroEstudante(valor: string): string {
  const digitos = (valor || '').replace(/\D/g, '').slice(0, 10)
  const p1 = digitos.slice(0, 2)
  const p2 = digitos.slice(2, 6)
  const p3 = digitos.slice(6, 10)
  return [p1, p2, p3].filter(Boolean).join('.')
}

export function validarNumeroEstudante(n: string): boolean {
  const s = normalizarNumeroEstudante(n)
  if (!s) return false
  return /^\d{2}\.\d{4}\.\d{4}$/.test(s)
}

export const MSG_NUMERO_INVALIDO =
  'Número de estudante inválido. Use o formato 00.0000.0000.'


