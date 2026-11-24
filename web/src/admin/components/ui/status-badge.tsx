import { corStatus } from '../../lib/format'
import type { DenunciaStatus } from '../../../lib/types'

export function StatusBadge({
  status,
  className = '',
}: {
  status: DenunciaStatus
  className?: string
}) {
  const cor = corStatus(status)
  return (
    <span
      className={`inline-flex items-center rounded-full border px-2.5 py-0.5 text-[11px] font-semibold ${className}`}
      style={{
        backgroundColor: `${cor}1A`,
        borderColor: `${cor}4D`,
        color: cor,
      }}
    >
      {status}
    </span>
  )
}
