import { format, parseISO } from 'date-fns'
import { ptBR } from 'date-fns/locale'
import type { DenunciaStatus } from './types'

export function formatarData(value: string | null | undefined): string {
  if (!value) return '—'
  const d = parseISO(value)
  if (Number.isNaN(d.getTime())) return '—'
  return format(d, 'dd/MM/yyyy', { locale: ptBR })
}

export function formatarDataHora(value: string | null | undefined): string {
  if (!value) return '—'
  const d = parseISO(value)
  if (Number.isNaN(d.getTime())) return '—'
  return format(d, "dd/MM/yyyy 'às' HH:mm", { locale: ptBR })
}

export function formatarDataCurta(value: string | null | undefined): string {
  if (!value) return '—'
  const d = parseISO(value)
  if (Number.isNaN(d.getTime())) return '—'
  return format(d, "dd/MM 'às' HH:mm", { locale: ptBR })
}

export function formatarBytes(bytes: number | null | undefined): string {
  if (!bytes) return '—'
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
}

export function corStatus(status: DenunciaStatus): string {
  switch (status) {
    case 'Recebida':
      return '#F39C12'
    case 'Em análise':
      return '#2980B9'
    case 'Investigação':
      return '#8E44AD'
    case 'Resolvida':
      return '#27AE60'
    case 'Encerrada':
      return '#6C757D'
  }
}

export function iconeStatus(status: DenunciaStatus): string {
  switch (status) {
    case 'Recebida':
      return 'inbox'
    case 'Em análise':
      return 'search'
    case 'Investigação':
      return 'microscope'
    case 'Resolvida':
      return 'check'
    case 'Encerrada':
      return 'lock'
  }
}

export function rotuloRole(role: string | null | undefined): string {
  switch (role) {
    case 'super_admin':
      return 'Super Administrador'
    case 'admin':
      return 'Administrador Nível 2'
    default:
      return 'Estudante'
  }
}

export function siglaNome(nome: string | null | undefined): string {
  if (!nome) return '?'
  const partes = nome.trim().split(/\s+/)
  if (partes.length === 1) return partes[0].slice(0, 2).toUpperCase()
  return (partes[0][0] + partes[partes.length - 1][0]).toUpperCase()
}

export function tipoMimePorExtensao(ext: string): string {
  const map: Record<string, string> = {
    jpg: 'image/jpeg',
    jpeg: 'image/jpeg',
    png: 'image/png',
    gif: 'image/gif',
    webp: 'image/webp',
    pdf: 'application/pdf',
    mp3: 'audio/mpeg',
    wav: 'audio/wav',
    mp4: 'video/mp4',
    mov: 'video/quicktime',
  }
  return map[ext.toLowerCase()] ?? 'application/octet-stream'
}