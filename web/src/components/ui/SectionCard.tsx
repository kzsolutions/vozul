import type { LucideIcon } from 'lucide-react'
import type { ReactNode } from 'react'
import { colors } from '../../config/theme'

interface Props {
  titulo: string
  icon: LucideIcon
  children: ReactNode
}

export default function SectionCard({ titulo, icon: Icone, children }: Props) {
  return (
    <section
      className="rounded-xl border bg-white p-4 shadow-sm"
      style={{ borderColor: colors.cinzaBorda }}
    >
      <div className="mb-4 flex items-center gap-2">
        <Icone className="h-5 w-5" style={{ color: colors.primario }} />
        <h2 className="text-[15px] font-bold" style={{ color: colors.primario }}>
          {titulo}
        </h2>
      </div>
      {children}
    </section>
  )
}
