import { useEffect } from 'react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { Bell, CheckCheck, MessageSquare } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import {
  Button,
  Popover,
  PopoverContent,
  PopoverTrigger,
  ScrollArea,
} from '../../components/ui'
import { Badge } from '../../components/ui'
import { Skeleton } from '../../components/ui'
import { useAuth } from '../../lib/auth'
import {
  listarNotificacoes,
  marcarNotificacaoLida,
  marcarTodasLidas,
  subscreverNotificacoes,
} from '../../lib/api/notificacoes'
import type { Notificacao } from '../../../lib/types'
import { formatarDataCurta } from '../../lib/format'
import { cn } from '../../../lib/utils'

export function NotificationsBell() {
  const { profile } = useAuth()
  const queryClient = useQueryClient()
  const navigate = useNavigate()
  const usuarioId = profile?.id

  const { data: notificacoes = [], isLoading } = useQuery({
    queryKey: ['notificacoes', usuarioId],
    queryFn: () => listarNotificacoes(usuarioId!),
    enabled: !!usuarioId,
    refetchInterval: 60_000,
  })

  useEffect(() => {
    if (!usuarioId) return
    const cancel = subscreverNotificacoes(usuarioId, (nova) => {
      queryClient.setQueryData<Notificacao[]>(
        ['notificacoes', usuarioId],
        (atual) => [nova, ...(atual ?? [])],
      )
    })
    return cancel
  }, [usuarioId, queryClient])

  const naoLidas = notificacoes.filter((n) => !n.lida).length

  const abrir = async (n: Notificacao) => {
    if (!n.lida) {
      await marcarNotificacaoLida(n.id)
      queryClient.invalidateQueries({ queryKey: ['notificacoes', usuarioId] })
    }
    if (n.denuncia_id) navigate(`/admin/denuncias/${n.denuncia_id}`)
  }

  const marcarTodas = async () => {
    if (!usuarioId) return
    await marcarTodasLidas(usuarioId)
    queryClient.invalidateQueries({ queryKey: ['notificacoes', usuarioId] })
  }

  return (
    <Popover>
      <PopoverTrigger asChild>
        <Button variant="ghost" size="icon" className="relative">
          <Bell className="size-5" />
          {naoLidas > 0 && (
            <span className="absolute -top-0.5 -right-0.5 flex size-4 items-center justify-center rounded-full bg-destructive text-[10px] font-bold text-white">
              {naoLidas > 9 ? '9+' : naoLidas}
            </span>
          )}
        </Button>
      </PopoverTrigger>
      <PopoverContent align="end" className="w-[22rem] max-w-[calc(100vw-1rem)] overflow-hidden rounded-xl border bg-popover p-0 shadow-xl">
        <div className="flex items-center justify-between border-b px-4 py-2">
          <p className="text-sm font-semibold">Notificações</p>
          {naoLidas > 0 && (
            <Button variant="ghost" size="sm" className="h-7 text-xs" onClick={marcarTodas}>
              <CheckCheck /> Marcar todas
            </Button>
          )}
        </div>
        <ScrollArea className="h-80">
          {isLoading ? (
            <div className="space-y-2 p-4">
              <Skeleton className="h-12 w-full" />
              <Skeleton className="h-12 w-full" />
            </div>
          ) : notificacoes.length === 0 ? (
            <div className="p-6 text-center text-sm text-muted-foreground">
              Sem notificações.
            </div>
          ) : (
            <div className="divide-y">
              {notificacoes.map((n) => (
                <button
                  key={n.id}
                  onClick={() => abrir(n)}
                  className={cn(
                    'flex w-full items-start gap-3 px-4 py-3 text-left transition-colors hover:bg-accent',
                    !n.lida && 'bg-primary/5',
                  )}
                >
                  <div className="mt-0.5 shrink-0 rounded-lg bg-primary/10 p-1.5 text-primary">
                    <MessageSquare className="size-4" />
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="text-sm font-medium leading-snug break-words">{n.titulo}</p>
                    <p className="line-clamp-2 text-xs leading-relaxed text-muted-foreground break-words">
                      {n.conteudo}
                    </p>
                    <p className="mt-1 text-[11px] leading-none text-muted-foreground">
                      {formatarDataCurta(n.created_at)}
                    </p>
                  </div>
                  {!n.lida && (
                    <Badge className="mt-1 h-2 w-2 shrink-0 rounded-full p-0" />
                  )}
                </button>
              ))}
            </div>
          )}
        </ScrollArea>
      </PopoverContent>
    </Popover>
  )
}