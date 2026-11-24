import { useEffect, useRef, useState } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import { ArrowLeft, CheckCheck, Info, Send, Shield, UserRound } from 'lucide-react'
import { supabase } from '../../config/supabase'
import { colors } from '../../config/theme'
import { formatarDataHora } from '../../lib/formatters'
import StatusChip from '../../components/ui/StatusChip'
import type { Denuncia, Mensagem } from '../../lib/types'

function displayCategoria(d: Denuncia): string {
  if (d.categoria === 'Outro' && d.categoria_custom) return d.categoria_custom
  return d.categoria
}

export default function Chat() {
  const navigate = useNavigate()
  const location = useLocation()
  const denuncia = (location.state as { denuncia?: Denuncia } | null)?.denuncia ?? null

  const [mensagens, setMensagens] = useState<Mensagem[]>([])
  const [texto, setTexto] = useState('')
  const [loading, setLoading] = useState(true)
  const [aEnviar, setAEnviar] = useState(false)
  const [erro, setErro] = useState('')
  const fimRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!denuncia) {
      navigate('/student/mensagens', { replace: true })
      return
    }
    iniciar()
    const canal = supabase
      .channel(`mensagens-${denuncia.id}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'mensagens',
          filter: `denuncia_id=eq.${denuncia.id}`,
        },
        () => {
          carregarMensagens()
          marcarLidas()
        }
      )
      .subscribe()
    return () => {
      supabase.removeChannel(canal)
    }
  }, [denuncia?.id])

  useEffect(() => {
    fimRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [mensagens])

  async function iniciar() {
    if (!denuncia) return
    setLoading(true)
    try {
      const { error } = await supabase.rpc('participar_denuncia', {
        codigo_procurado: denuncia.codigo,
      })
      if (error) {
        setErro('Não foi possível abrir a conversa. Tente novamente.')
        setLoading(false)
        return
      }
      await carregarMensagens()
      await marcarLidas()
    } catch {
      setErro('Não foi possível abrir a conversa. Tente novamente.')
    } finally {
      setLoading(false)
    }
  }

  async function carregarMensagens() {
    if (!denuncia) return
    const { data } = await supabase
      .from('mensagens')
      .select('*')
      .eq('denuncia_id', denuncia.id)
      .order('created_at', { ascending: true })
    setMensagens((data as Mensagem[]) ?? [])
  }

  async function marcarLidas() {
    if (!denuncia) return
    await supabase
      .from('mensagens')
      .update({ lida: true })
      .eq('denuncia_id', denuncia.id)
      .eq('remetente', 'comissao')
      .eq('lida', false)
  }

  async function enviar() {
    if (!denuncia) return
    const conteudo = texto.trim()
    if (!conteudo || aEnviar) return
    setAEnviar(true)
    setErro('')
    const { error } = await supabase.from('mensagens').insert({
      denuncia_id: denuncia.id,
      remetente: 'estudante',
      conteudo,
      lida: false,
    })
    if (error) {
      setErro('Não foi possível enviar a mensagem. Tente novamente.')
    } else {
      setTexto('')
      await carregarMensagens()
    }
    setAEnviar(false)
  }

  if (!denuncia) return null

  return (
    <div className="mx-auto flex h-[calc(100vh-8rem)] max-w-3xl flex-col overflow-hidden rounded-xl border bg-white shadow-sm" style={{ borderColor: colors.cinzaBorda }}>
      <div className="border-b px-4 py-3" style={{ borderColor: colors.cinzaBorda }}>
        <div className="flex items-center gap-3">
          <button
            onClick={() => navigate(-1)}
            className="rounded-full p-1.5 hover:bg-gray-100"
            aria-label="Voltar"
          >
            <ArrowLeft className="h-5 w-5" style={{ color: colors.primario }} />
          </button>
          <span
            className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full"
            style={{
              background: `linear-gradient(135deg, ${colors.primarioClaro}, ${colors.primario})`,
            }}
          >
            {denuncia.anonima ? (
              <Shield className="h-5 w-5 text-white" />
            ) : (
              <UserRound className="h-5 w-5 text-white" />
            )}
          </span>
          <div className="min-w-0 flex-1">
            <p className="truncate text-sm font-bold" style={{ color: colors.primario }}>
              {denuncia.codigo}
              {denuncia.anonima && (
                <span
                  className="ml-2 rounded-full px-2 py-0.5 text-[10px] font-semibold"
                  style={{ background: colors.verdeClaro, color: colors.verde }}
                >
                  Anónima
                </span>
              )}
            </p>
            <p className="truncate text-xs" style={{ color: colors.cinza }}>
              {displayCategoria(denuncia)} • {denuncia.faculdade}
            </p>
          </div>
          <StatusChip status={denuncia.status} />
        </div>
      </div>

      <div className="flex-1 space-y-3 overflow-y-auto px-4 py-4" style={{ background: colors.cinzaClaro }}>
        {loading ? (
          <p className="py-10 text-center text-sm" style={{ color: colors.cinza }}>
            A carregar mensagens...
          </p>
        ) : mensagens.length === 0 ? (
          <div className="py-10 text-center">
            <Info className="mx-auto mb-2 h-8 w-8" style={{ color: colors.cinza }} />
            <p className="text-sm font-semibold" style={{ color: colors.primario }}>
              Ainda não há mensagens
            </p>
            <p className="mt-1 text-xs" style={{ color: colors.cinza }}>
              Envie a primeira mensagem à Comissão de Ética.
            </p>
          </div>
        ) : (
          mensagens.map((m) => {
            const minha = m.remetente === 'estudante'
            return (
              <div key={m.id} className={`flex ${minha ? 'justify-end' : 'justify-start'}`}>
                <div className="max-w-[78%]">
                  <div
                    className="rounded-2xl px-3.5 py-2.5 text-[13px] leading-relaxed"
                    style={
                      minha
                        ? {
                            background: colors.primario,
                            color: '#fff',
                            borderBottomRightRadius: 4,
                          }
                        : {
                            background: '#fff',
                            color: '#212529',
                            border: `1px solid ${colors.cinzaBorda}`,
                            borderBottomLeftRadius: 4,
                          }
                    }
                  >
                    {!minha && (
                      <p
                        className="mb-1 text-[10px] font-bold uppercase tracking-wide"
                        style={{ color: colors.primarioClaro }}
                      >
                        Comissão de Ética
                      </p>
                    )}
                    <p className="whitespace-pre-wrap break-words">{m.conteudo}</p>
                  </div>
                  <div
                    className={`mt-1 flex items-center gap-1 ${minha ? 'justify-end' : 'justify-start'}`}
                  >
                    <span className="text-[10px]" style={{ color: colors.cinza }}>
                      {formatarDataHora(m.created_at)}
                    </span>
                    {minha && m.lida && (
                      <CheckCheck className="h-3 w-3" style={{ color: colors.primarioClaro }} />
                    )}
                  </div>
                </div>
              </div>
            )
          })
        )}
        <div ref={fimRef} />
      </div>

      {erro && (
        <p className="px-4 py-2 text-xs" style={{ color: colors.vermelho }}>
          {erro}
        </p>
      )}

      <div className="border-t p-3" style={{ borderColor: colors.cinzaBorda }}>
        <div className="flex items-end gap-2">
          <textarea
            value={texto}
            onChange={(e) => setTexto(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault()
                enviar()
              }
            }}
            rows={1}
            placeholder="Escreva a sua mensagem..."
            className="max-h-32 min-h-11 flex-1 resize-none rounded-xl border px-3 py-2.5 text-sm outline-none focus:ring-2"
            style={{ borderColor: colors.cinzaBorda }}
          />
          <button
            onClick={enviar}
            disabled={aEnviar || !texto.trim()}
            className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl text-white disabled:opacity-50"
            style={{ background: colors.primario }}
            aria-label="Enviar"
          >
            <Send className="h-4 w-4" />
          </button>
        </div>
      </div>
    </div>
  )
}
