import { useQuery } from '@tanstack/react-query'
import { useNavigate } from 'react-router-dom'
import { Loader2, MessageCircle } from 'lucide-react'
import { Badge, Card, CardContent, Skeleton, StatusBadge } from '../../components/ui'
import { useAuth } from '../../lib/auth'
import { listarConversas } from '../../lib/api/mensagens'
import { corStatus, formatarDataCurta } from '../../lib/format'
import type { Conversa } from '../../lib/api/mensagens'

export function MensagensListScreen() {
  const { visaoGlobal, profile } = useAuth()
  const faculdade = visaoGlobal ? null : profile?.faculdade ?? null

  const { data: conversas, isLoading, error } = useQuery({
    queryKey: ['conversas', faculdade],
    queryFn: () => listarConversas(faculdade),
    refetchInterval: 30_000,
  })

  return (
    <div className="space-y-4">
      <div className="text-sm text-muted-foreground">
        {visaoGlobal
          ? 'Todas as conversas, de todas as faculdades.'
          : `Conversas da ${profile?.faculdade ?? 'sua faculdade'}.`}
      </div>

      {isLoading ? (
        <div className="space-y-3">
          {Array.from({ length: 5 }).map((_, i) => (
            <Skeleton key={i} className="h-16" />
          ))}
        </div>
      ) : error ? (
        <Card>
          <CardContent className="p-6 text-sm text-destructive">
            Não foi possível carregar as conversas: {error.message}
          </CardContent>
        </Card>
      ) : !conversas || conversas.length === 0 ? (
        <Card>
          <CardContent className="flex flex-col items-center gap-3 p-10 text-center">
            <MessageCircle className="size-10 text-muted-foreground" />
            <p className="font-medium">Sem conversas</p>
            <p className="max-w-sm text-sm text-muted-foreground">
              Quando estudantes responderem a denúncias, as conversas aparecem aqui.
            </p>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-3">
          {conversas.map((c) => (
            <ConversaRow key={c.denuncia.id} c={c} />
          ))}
        </div>
      )}
    </div>
  )
}

function ConversaRow({ c }: { c: Conversa }) {
  const navigate = useNavigate()
  return (
    <Card
      className="cursor-pointer transition-shadow hover:shadow-md"
      onClick={() => navigate(`/admin/mensagens/${c.denuncia.id}`)}
    >
      <CardContent className="flex items-center gap-4 p-4">
        <div
          className="flex size-10 shrink-0 items-center justify-center rounded-full text-xs font-bold text-white"
          style={{ backgroundColor: corStatus(c.denuncia.status) }}
        >
          {c.denuncia.codigo?.split('-')[1] ?? c.denuncia.id}
        </div>
        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-2">
            <p className="font-mono text-xs font-semibold text-muted-foreground">
              {c.denuncia.codigo}
            </p>
            <StatusBadge status={c.denuncia.status} className="text-[10px]" />
            {c.naoLidas > 0 && <Badge variant="destructive">{c.naoLidas} não lidas</Badge>}
            {c.denuncia.anonima && <Badge variant="secondary">Anónima</Badge>}
          </div>
          <p className="mt-1 truncate text-sm text-muted-foreground">
            {c.ultimaMensagem ?? 'Sem mensagens'}
          </p>
        </div>
        <div className="shrink-0 text-xs text-muted-foreground">
          {c.ultimaData ? formatarDataCurta(c.ultimaData) : '—'}
        </div>
      </CardContent>
    </Card>
  )
}

export function ConversaVazia() {
  return (
    <div className="flex flex-col items-center gap-2 p-10 text-center text-muted-foreground">
      <Loader2 className="size-8" />
      <p className="text-sm">A carregar conversa…</p>
    </div>
  )
}