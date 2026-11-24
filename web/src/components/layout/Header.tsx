import { useCallback, useEffect, useState } from 'react'
import { Bell, BellRing, CheckCheck } from 'lucide-react'
import { colors } from '../../config/theme'
import { useAuth } from '../../contexts/AuthContext'
import { supabase } from '../../config/supabase'
import { formatarDataHora } from '../../lib/formatters'

interface Notificacao {
  id: number
  titulo: string | null
  conteudo: string | null
  lida: boolean
  created_at: string
}

export default function Header() {
  const { profile, user } = useAuth()
  const nome = profile?.nome_completo || profile?.email || 'Estudante'
  const [open, setOpen] = useState(false)
  const [notificacoes, setNotificacoes] = useState<Notificacao[]>([])

  const carregar = useCallback(async () => {
    if (!user?.id) return
    const { data } = await supabase
      .from('notificacoes')
      .select('id,titulo,conteudo,lida,created_at')
      .eq('usuario_id', user.id)
      .order('created_at', { ascending: false })
      .limit(20)
    setNotificacoes((data as Notificacao[]) ?? [])
  }, [user?.id])

  useEffect(() => {
    carregar()
    const intervalo = setInterval(carregar, 60000)
    return () => clearInterval(intervalo)
  }, [carregar])

  const naoLidas = notificacoes.filter((n) => !n.lida).length

  async function marcarTodasComoLidas() {
    if (!user?.id) return
    await supabase
      .from('notificacoes')
      .update({ lida: true })
      .eq('usuario_id', user.id)
      .eq('lida', false)
    carregar()
  }

  async function marcarComoLida(id: number) {
    await supabase.from('notificacoes').update({ lida: true }).eq('id', id)
    carregar()
  }

  return (
    <header
      className="sticky top-0 z-10 flex h-16 items-center justify-between border-b bg-white px-6"
      style={{ borderColor: colors.cinzaBorda }}
    >
      <div>
        <p className="text-sm text-gray-500">Bem-vindo</p>
        <p className="font-semibold" style={{ color: colors.primario }}>
          {nome}
        </p>
      </div>

      <div className="relative">
        <button
          onClick={() => setOpen((v) => !v)}
          className="relative rounded-lg p-2 hover:bg-gray-50"
        >
          <Bell className="h-5 w-5" style={{ color: colors.cinza }} />
          {naoLidas > 0 && (
            <span
              className="absolute -right-0.5 -top-0.5 flex h-4 min-w-4 items-center justify-center rounded-full px-1 text-[10px] font-bold text-white"
              style={{ background: colors.vermelho }}
            >
              {naoLidas}
            </span>
          )}
        </button>

        {open && (
          <div
            className="absolute right-0 mt-2 max-h-[70vh] w-96 overflow-y-auto rounded-xl border bg-white shadow-lg"
            style={{ borderColor: colors.cinzaBorda }}
          >
            <div
              className="flex items-center justify-between border-b px-4 py-3"
              style={{ borderColor: colors.cinzaBorda }}
            >
              <p className="font-semibold">Notificações</p>
              {naoLidas > 0 && (
                <button
                  onClick={marcarTodasComoLidas}
                  className="flex items-center gap-1 text-xs font-medium"
                  style={{ color: colors.primario }}
                >
                  <CheckCheck className="h-4 w-4" />
                  Marcar todas como lidas
                </button>
              )}
            </div>

            {notificacoes.length === 0 ? (
              <div className="p-4 text-sm text-gray-600">Sem notificações</div>
            ) : (
              <div className="space-y-2 p-3">
                {notificacoes.map((n) => (
                  <button
                    key={n.id}
                    onClick={() => !n.lida && marcarComoLida(n.id)}
                    className="flex w-full items-start gap-3 rounded-xl border p-3 text-left transition"
                    style={{
                      borderColor: n.lida ? colors.cinzaBorda : colors.primario + '4D',
                      background: n.lida ? '#fff' : colors.primarioClaro + '14',
                    }}
                  >
                    {n.lida ? (
                      <Bell className="mt-0.5 h-5 w-5" style={{ color: colors.cinza }} />
                    ) : (
                      <BellRing className="mt-0.5 h-5 w-5" style={{ color: colors.primario }} />
                    )}
                    <div className="min-w-0 flex-1">
                      <div className="flex items-start justify-between gap-2">
                        <p className={'text-sm ' + (n.lida ? 'font-semibold' : 'font-extrabold')}>
                          {n.titulo ?? 'Notificação'}
                        </p>
                        <span className="shrink-0 text-[10px]" style={{ color: colors.cinza }}>
                          {formatarDataHora(n.created_at)}
                        </span>
                      </div>
                      <p className="mt-1 text-xs" style={{ color: colors.cinza }}>
                        {n.conteudo ?? ''}
                      </p>
                    </div>
                  </button>
                ))}
              </div>
            )}
          </div>
        )}
      </div>
    </header>
  )
}
