function paraData(valor?: string | Date | null): Date | null {
  if (!valor) return null
  if (valor instanceof Date) return isNaN(valor.getTime()) ? null : valor
  const data = new Date(valor)
  return isNaN(data.getTime()) ? null : data
}

function doisDigitos(n: number): string {
  return n.toString().padStart(2, '0')
}

export function formatarData(valor?: string | Date | null): string {
  const data = paraData(valor)
  if (!data) return '—'
  return `${doisDigitos(data.getDate())}/${doisDigitos(data.getMonth() + 1)}/${data.getFullYear()}`
}

export function formatarDataHora(valor?: string | Date | null): string {
  const data = paraData(valor)
  if (!data) return '—'
  return `${formatarData(data)} ${doisDigitos(data.getHours())}:${doisDigitos(data.getMinutes())}`
}

export function formatarTamanho(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
}

export function dataIsoHoje(): string {
  const hoje = new Date()
  return `${hoje.getFullYear()}-${doisDigitos(hoje.getMonth() + 1)}-${doisDigitos(hoje.getDate())}`
}
