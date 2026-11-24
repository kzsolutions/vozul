import { useEffect, useMemo, useRef, useState } from 'react'
import type { FormEvent } from 'react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { ArrowLeft, Loader2, Send } from 'lucide-react'
import { toast } from 'sonner'
import { Button, Card, Input, Skeleton } from '../../components/ui'
import { ScrollArea } from '../../components/ui'
import { useAuth } from '../../lib/auth'
import { obterDenuncia } from '../../lib/api/denuncias'
import {
  enviarMensagem,
  listarMensagens,
  marcarMensagensLidasComissao,
  subscreverMensagens,
} from '../../lib/api/mensagens'
import { formatarDataHora } from '../../lib/format'
import { registrarAcesso } from '../../lib/api/historico'
import type { Mensagem } from '../../../lib/types'

export function ChatScreen() {
  const { id } = useParams()
  const denunciaId = Number(id)
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const { profile, isSuperAdmin } = useAuth()
  const [conteudo, setConteudo] = useState('')
  const [enviando, setEnviando] = useState(false)
  const bottomRef = useRef<HTMLDivElement>(null)
  const soLeitura = isSuperAdmin

  const { data: denuncia } = useQuery({
    queryKey: ['denuncia', denunciaId],
    queryFn: () => obterDenuncia(denunciaId),
    enabled: Number.isInteger(denunciaId) && denunciaId > 0,
  })

  const { data: mensagens = [], isLoading } = useQuery({
    queryKey: ['mensagens', denunciaId],
    queryFn: async () => {
      const msgs = await listarMensagens(denunciaId)
      if (profile) {
        await marcarMensagensLidasComissao(denunciaId).catch(() => {})
      }
      return msgs
    },
    enabled: Number.isInteger(denunciaId) && denunciaId > 0 && !!profile,
  })

  useEffect(() => {
    if (!Number.isInteger(denunciaId)) return
    const cancel = subscreverMensagens(denunciaId, (nova) => {
      queryClient.setQueryData<Mensagem[]>(['mensagens', denunciaId], (atual) => [
        ...(atual ?? []),
        nova,
      ])
    })
    return cancel
  }, [denunciaId, queryClient])

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [mensagens.length])

  const naoLidas = useMemo(
    () => mensagens.filter((m) => m.remetente === 'estudante' && !m.lida).length,
    [mensagens],
  )

  const enviar = async (e: FormEvent) => {
    e.preventDefault()
    const texto = conteudo.trim()
    if (!texto || enviando || !profile) return
    setEnviando(true)
    try {
      await enviarMensagem(denunciaId, texto)
      setConteudo('')
      await registrarAcesso({
        usuarioId: profile.id,
        acao: 'Resposta a denúncia',
        recurso: 'mensagens',
        registroId: String(denunciaId),
        detalhes: `Denúncia #${denunciaId}`,
      })
      queryClient.invalidateQueries({ queryKey: ['mensagens', denunciaId] })
      queryClient.invalidateQueries({ queryKey: ['conversas'] })
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Erro ao enviar mensagem')
    } finally {
      setEnviando(false)
    }
  }

  return (
    <div className="flex h-[calc(100vh-140px)] min-h-[420px] flex-col">
      <header className="mb-3 flex items-center gap-3">
        <Button variant="ghost" size="icon" onClick={() => navigate('/admin/mensagens')}>
          <ArrowLeft className="size-4" />
        </Button>
        {denuncia ? (
          <div>
            <Link
              to={`/admin/denuncias/${denuncia.id}`}
              className="font-mono text-sm font-bold hover:underline"
            >
              {denuncia.codigo}
            </Link>
            <p className="text-xs text-muted-foreground">
              Conversa com {denuncia.anonima ? 'denunciante anónimo' : 'denunciante'} ·{' '}
              {denuncia.faculdade}
            </p>
          </div>
        ) : (
          <Skeleton className="h-9 w-40" />
        )}
        <div className="flex-1" />
        {naoLidas > 0 && (
          <span className="rounded-full bg-primary/10 px-3 py-1 text-xs font-semibold text-primary">
            {naoLidas} nova(s)
          </span>
        )}
      </header>

      {denuncia && !denuncia.anonima && denuncia.status === 'Recebida' && (
        <div className="mb-2 rounded-lg border border-amber-300/50 bg-amber-50 p-2 text-xs text-amber-700">
          Mantenha o tom profissional. Lembre-se: esta conversa pode ser apresentada
          no processo disciplinar.
        </div>
      )}

      <Card className="flex min-h-0 flex-1 flex-col">
        <ScrollArea className="flex-1 p-4">
          {isLoading ? (
            <div className="space-y-3">
              <Skeleton className="h-10 w-2/3" />
              <Skeleton className="ml-auto h-10 w-1/2" />
            </div>
          ) : mensagens.length === 0 ? (
            <div className="flex h-full items-center justify-center text-sm text-muted-foreground">
              Inicie a conversa com o denunciante.
            </div>
          ) : (
            <div className="space-y-3">
              {mensagens.map((m) => (
                <MensagemBubble key={m.id} m={m} />
              ))}
              <div ref={bottomRef} />
            </div>
          )}
        </ScrollArea>

        {soLeitura ? (
          <div className="border-t p-3 text-center text-xs text-muted-foreground">
            O Super Administrador vê a conversa em modo de leitura.
          </div>
        ) : (
          <form onSubmit={enviar} className="flex items-center gap-2 border-t p-3">
            <Input
              className="flex-1"
              placeholder="Escreva uma mensagem…"
              value={conteudo}
              onChange={(e) => setConteudo(e.target.value)}
            />
            <Button type="submit" size="icon" disabled={!conteudo.trim() || enviando}>
              {enviando ? <Loader2 className="animate-spin" /> : <Send />}
            </Button>
          </form>
        )}
      </Card>
    </div>
  )
}

function MensagemBubble({ m }: { m: Mensagem }) {
  const daComissao = m.remetente === 'comissao'
  return (
    <div className={`flex ${daComissao ? 'justify-end' : 'justify-start'}`}>
      <div
        className={`max-w-[75%] rounded-2xl px-4 py-2 text-sm ${
          daComissao ? 'bg-primary text-primary-foreground' : 'bg-muted'
        }`}
      >
        <p className="whitespace-pre-wrap">{m.conteudo}</p>
        <p
          className={`mt-1 text-right text-[10px] ${daComissao ? 'text-primary-foreground/70' : 'text-muted-foreground'}`}
        >
          {daComissao ? 'Comissão' : 'Estudante'} · {formatarDataHora(m.created_at)}
        </p>
      </div>
    </div>
  )
}