import { useQuery } from '@tanstack/react-query'
import { Download, FileText, Loader2, X } from 'lucide-react'
import { Button } from '../../components/ui'
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '../../components/ui'
import { obterUrlAssinada } from '../../lib/api/denuncias'
import { classificacaoFicheiro } from '../../lib/detect'
import { formatarBytes } from '../../lib/format'
import type { Evidencia } from '../../../lib/types'

export function EvidenceViewer({
  evidencia,
  onClose,
}: {
  evidencia: Evidencia
  onClose: () => void
}) {
  const { data: url, isLoading } = useQuery({
    queryKey: ['evidencia-url', evidencia.file_url],
    queryFn: () => obterUrlAssinada(evidencia.file_url),
  })

  const tipo = classificacaoFicheiro(evidencia.file_type)

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="max-w-3xl">
        <DialogHeader className="flex flex-row items-center justify-between pr-8">
          <DialogTitle className="truncate text-base">
            {evidencia.file_name ?? 'Prova'}
          </DialogTitle>
          <Button
            variant="outline"
            size="icon"
            onClick={() => window.open(url, '_blank', 'noopener')}
            disabled={!url}
            title="Abrir em nova aba"
          >
            <Download className="size-4" />
          </Button>
        </DialogHeader>

        <div className="min-h-64 w-full rounded-lg bg-muted/40">
          {isLoading || !url ? (
            <div className="flex h-64 items-center justify-center">
              <Loader2 className="animate-spin text-muted-foreground" />
            </div>
          ) : tipo === 'imagem' ? (
            <img
              src={url}
              alt={evidencia.file_name}
              className="mx-auto max-h-[70vh] rounded-lg object-contain"
            />
          ) : tipo === 'video' ? (
            <video src={url} controls className="mx-auto max-h-[70vh] rounded-lg" />
          ) : tipo === 'audio' ? (
            <div className="flex h-64 flex-col items-center justify-center gap-4">
              <p className="text-sm text-muted-foreground">
                {evidencia.file_name} · {formatarBytes(evidencia.file_size)}
              </p>
              <audio src={url} controls className="w-full max-w-md" />
            </div>
          ) : tipo === 'pdf' ? (
            <iframe
              src={url}
              title={evidencia.file_name}
              className="h-[70vh] w-full rounded-lg"
            />
          ) : (
            <div className="flex h-64 flex-col items-center justify-center gap-3 text-muted-foreground">
              <FileText className="size-10" />
              <p className="text-sm">
                Só pode ser vista através do download.
              </p>
            </div>
          )}
        </div>

        <div className="flex items-center justify-between text-xs text-muted-foreground">
          <span className="truncate">
            {evidencia.file_name} · {formatarBytes(evidencia.file_size)}
          </span>
          <Button variant="ghost" size="sm" className="text-xs" onClick={onClose}>
            <X /> Fechar
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  )
}