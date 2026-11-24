import type { LucideIcon } from 'lucide-react'
import type { ReactNode } from 'react'
import { colors } from '../../config/theme'

interface Props {
  icon: LucideIcon
  mensagem: string
  subtitulo?: string
  action?: ReactNode
}

export default function EmptyState({ icon: Icone, mensagem, subtitulo, action }: Props) {
  return (
    <div className="flex flex-col items-center justify-center px-6 py-12 text-center">
      <div
        className="flex h-22 w-22 items-center justify-center rounded-full"
        style={{ width: 88, height: 88, backgroundColor: colors.cinzaClaro }}
      >
        <Icone className="h-11 w-11" style={{ color: colors.cinza }} />
      </div>
      <p className="mt-5 text-base font-semibold" style={{ color: colors.primario }}>
        {mensagem}
      </p>
      {subtitulo && (
        <p className="mt-2 max-w-sm text-sm" style={{ color: colors.cinza }}>
          {subtitulo}
        </p>
      )}
      {action && <div className="mt-6">{action}</div>}
    </div>
  )
}
