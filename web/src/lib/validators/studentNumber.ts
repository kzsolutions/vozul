export function normalizarNumeroEstudante(n: string): string {
  return (n || '').trim()
}

export function validarNumeroEstudante(n: string): boolean {
  const s = normalizarNumeroEstudante(n)
  if (!s) return false
  return /^\d{2}\.\d{4}\.\d{4}$/.test(s)
}

export const MSG_NUMERO_INVALIDO =
  'Número de estudante inválido. Use o formato 05.1234.2026.'


