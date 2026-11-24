import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ChevronRight, MessageSquare, Shield, UserRound } from 'lucide-react'
import { supabase } from '../../config/supabase'
import { colors } from '../../config/theme'
import { useAuth } from '../../contexts/AuthContext'
import { formatarDataHora } from '../../lib/formatters'
import EmptyState from '../../components/ui/EmptyState'
import type { Denuncia } from '../../lib/types'

interface Conversa extends Denuncia {
  ultima_mensagem?: string | null
  ultima_mensagem_data?: string | null
  nao_lidas?: number
}

function displayCategoria(d: Denuncia): string {
  if (d.categoria === 'Outro' && d.categoria_custom) return d.categoria_custom
  return d.categoria
}

export default function Mensagens() {
  const { user } = useAuth()
  const navigate = useNavigate()
  const [conversas, setConversas] = useState<Conversa[]>([])
  const [loading, setLoading] = useState(true)
  const [erro, setErro] = useState('')

  useEffect(() => {
    if (!user?.id) return
    carregar()
    const intervalo = setInterval(carregar, 30000)
    return () => clearInterval(intervalo)
  }, [user?.id])

  async function carregar() {
    const { data, error } = await supabase.rpc('listar_minhas_denuncias')
    if (error) {
      setErro('Não foi possível carregar as conversas. Tente novamente.')
    } else {
      const todas = ((data as Conversa[]) ?? []) as Conversa[]
      setConversas(todas.filter((d) => d.ultima_mensagem))
      setErro('')
    }
    setLoading(false)
  }

  function abrir(conversa: Conversa) {
    navigate('/student/chat', { state: { denuncia: conversa } })
  }

  const totalNaoLidas = conversas.reduce((soma, d) => soma + (d.nao_lidas ?? 0), 0)

  return (
    <div className="mx-auto max-w-3xl space-y-5">
      <div>
        <h1 className="text-xl font-bold" style={{ color: colors.primario }}>
          Mensagens
        </h1>
        <p className="mt-1 text-[13px]" style={{ color: colors.cinza }}>
          Comunicação com a Comissão de Ética
          {totalNaoLidas > 0 && (
            <span className="font-semibold" style={{ color: colors.vermelho }}>
              {' '}
              • {totalNaoLidas} nova{totalNaoLidas === 1 ? '' : 's'}
            </span>
          )}
        </p>
      </div>

      {loading ? (
        <div className="py-12 text-center text-sm" style={{ color: colors.cinza }}>
          A carregar conversas...
        </div>
      ) : erro ? (
        <div className="rounded-xl border bg-white p-6 text-center" style={{ borderColor: colors.cinzaBorda }}>
          <p className="text-sm" style={{ color: colors.vermelho }}>
            {erro}
          </p>
          <button
            onClick={carregar}
            className="mt-3 rounded-lg px-4 py-2 text-sm font-semibold text-white"
            style={{ background: colors.primario }}
          >
            Tentar novamente
          </button>
        </div>
      ) : conversas.length === 0 ? (
        <div className="rounded-xl border bg-white" style={{ borderColor: colors.cinzaBorda }}>
          <EmptyState
            icon={MessageSquare}
            mensagem="Nenhuma conversa ainda"
            subtitulo="As conversas com a Comissão de Ética aparecerão aqui."
          />
        </div>
      ) : (
        <div className="space-y-2.5">
          {conversas.map((d) => {
            const naoLidas = d.nao_lidas ?? 0
            return (
              <button
                key={d.id}
                onClick={() => abrir(d)}
                className="flex w-full items-center gap-3.5 rounded-xl border bg-white p-3.5 text-left shadow-sm transition hover:shadow-md"
                style={{ borderColor: colors.cinzaBorda }}
              >
                <span
                  className="flex h-12 w-12 shrink-0 items-center justify-center rounded-full"
                  style={{
                    background: `linear-gradient(135deg, ${colors.primarioClaro}, ${colors.primario})`,
                  }}
                >
                  {d.anonima ? (
                    <Shield className="h-6 w-6 text-white" />
                  ) : (
                    <UserRound className="h-6 w-6 text-white" />
                  )}
                </span>

                <span className="min-w-0 flex-1">
                  <span className="flex items-center gap-2">
                    <span className="truncate text-sm font-bold" style={{ color: colors.primario }}>
                      {d.codigo}
                    </span>
                    {d.anonima && (
                      <span
                        className="shrink-0 rounded-full px-2 py-0.5 text-[10px] font-semibold"
                        style={{ background: colors.verdeClaro, color: colors.verde }}
                      >
                        Anónima
                      </span>
                    )}
                  </span>
                  <span className="mt-0.5 block truncate text-xs" style={{ color: colors.cinza }}>
                    {displayCategoria(d)} • {d.faculdade}
                  </span>
                  <span
                    className="mt-1 block truncate text-[13px]"
                    style={{
                      color: naoLidas > 0 ? colors.primario : colors.cinza,
                      fontWeight: naoLidas > 0 ? 600 : 400,
                    }}
                  >
                    {d.ultima_mensagem}
                  </span>
                </span>

                <span className="flex shrink-0 flex-col items-end gap-1.5">
                  <span className="text-[11px]" style={{ color: colors.cinza }}>
                    {d.ultima_mensagem_data ? formatarDataHora(d.ultima_mensagem_data) : ''}
                  </span>
                  {naoLidas > 0 ? (
                    <span
                      className="flex h-5 min-w-5 items-center justify-center rounded-full px-1.5 text-[10px] font-bold text-white"
                      style={{ background: colors.vermelho }}
                    >
                      {naoLidas > 9 ? '9+' : naoLidas}
                    </span>
                  ) : (
                    <ChevronRight className="h-4 w-4" style={{ color: colors.cinzaBorda }} />
                  )}
                </span>
              </button>
            )
          })}
        </div>
      )}
    </div>
  )
}
