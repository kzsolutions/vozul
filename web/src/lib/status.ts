import {
  CheckCircle2,
  CircleHelp,
  ClipboardCheck,
  Lock,
  MailCheck,
  Search,
  type LucideIcon,
} from 'lucide-react'
import { colors } from '../config/theme'
import type { DenunciaStatus } from './types'

export const STATUS_DENUNCIA: DenunciaStatus[] = [
  'Recebida',
  'Em análise',
  'Investigação',
  'Resolvida',
  'Encerrada',
]

export function corStatus(status: string): string {
  switch (status) {
    case 'Recebida':
      return colors.statusRecebida
    case 'Em análise':
      return colors.statusEmAnalise
    case 'Investigação':
      return colors.statusInvestigacao
    case 'Resolvida':
      return colors.statusResolvida
    case 'Encerrada':
      return colors.statusEncerrada
    default:
      return colors.cinza
  }
}

export function iconeStatus(status: string): LucideIcon {
  switch (status) {
    case 'Recebida':
      return MailCheck
    case 'Em análise':
      return Search
    case 'Investigação':
      return ClipboardCheck
    case 'Resolvida':
      return CheckCircle2
    case 'Encerrada':
      return Lock
    default:
      return CircleHelp
  }
}
