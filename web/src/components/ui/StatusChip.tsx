import { corStatus, iconeStatus } from '../../lib/status'

interface Props {
  status: string
}

export default function StatusChip({ status }: Props) {
  const cor = corStatus(status)
  const Icone = iconeStatus(status)

  return (
    <span
      className="inline-flex items-center gap-1 rounded-full border px-2.5 py-1 text-xs font-semibold"
      style={{ color: cor, borderColor: cor + '4D', backgroundColor: cor + '1A' }}
    >
      <Icone className="h-3.5 w-3.5" />
      {status}
    </span>
  )
}
