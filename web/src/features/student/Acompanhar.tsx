import { useEffect, useState } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import {
  CalendarDays,
  Flag,
  Hash,
  Inbox,
  Landmark,
  MapPin,
  MessageSquare,
  Search,
  School,
  Tags,
  X,
  type LucideIcon,
} from 'lucide-react'
import { supabase } from '../../config/supabase'
import { colors } from '../../config/theme'
import { useAuth } from '../../contexts/AuthContext'
import { formatarData, formatarDataHora } from '../../lib/formatters'
import { STATUS_DENUNCIA, corStatus, iconeStatus } from '../../lib/status'
import { carregarCodigos, removerCodigo } from '../../lib/codigosGuardados'
import StatusChip from '../../components/ui/StatusChip'
import EmptyState from '../../components/ui/EmptyState'
import type { Denuncia } from '../../lib/types'

interface DenunciaComMensagem extends Denuncia {
  ultima_mensagem?: string | null
  ultima_mensagem_data?: string | null
  nao_lidas?: number
}

function extrairLinha(data: unknown): Record<string, any> | null {
  if (Array.isArray(data)) return (data[0] as Record<string, any>) ?? null
  if (data && typeof data === 'object') return data as Record<string, any>
  return null
}

function displayCategoria(d: Denuncia): string {
  if (d.categoria === 'Outro' && d.categoria_custom) return d.categoria_custom
  return d.categoria
}

function DetalheLinha({
  icon: Icone,
  label,
  valor,
}: {
  icon: LucideIcon
  label: string
  valor: string
}) {
  return (
    <div className="flex items-start gap-2.5 py-1">
      <Icone className="mt-0.5 h-4 w-4 shrink-0" style={{ color: colors.cinza }} />
      <span className="w-32 shrink-0 text-[13px]" style={{ color: colors.cinza }}>
        {label}
      </span>
      <span className="flex-1 text-[13px] font-medium">{valor}</span>
    </div>
  )
}

function Timeline({ statusAtual }: { statusAtual: string }) {
  const atual = STATUS_DENUNCIA.indexOf(statusAtual as any)
  return (
    <div className="space-y-0">
      {STATUS_DENUNCIA.map((status, index) => {
        const cor = corStatus(status)
        const concluido = index <= atual
        return (
          <div key={status} className="flex items-start gap-3">
            <div className="flex flex-col items-center">
              <div
                className="flex items-center justify-center rounded-full border-2 text-[10px] font-bold"
                style={{
                  width: 24,
                  height: 24,
                  borderColor: concluido ? cor : colors.cinzaBorda,
                  background: concluido ? cor : colors.cinzaClaro,
                  color: concluido ? '#fff' : colors.cinza,
                }}
              >
                {concluido ? '✓' : ''}
              </div>
              {index < STATUS_DENUNCIA.length - 1 && (
                <div
                  style={{
                    width: 2,
                    height: 28,
                    background: index < atual ? cor : colors.cinzaBorda,
                  }}
                />
              )}
            </div>
            <p
              className="pb-2.5 pt-0.5 text-[13px]"
              style={{
                color: concluido ? cor : colors.cinza,
                fontWeight: index === atual ? 800 : 500,
              }}
            >
              {status}
            </p>
          </div>
        )
      })}
    </div>
  )
}

export default function Acompanhar({ publico = false }: { publico?: boolean }) {
  const { user } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()

  const [codigo, setCodigo] = useState('')
  const [loading, setLoading] = useState(false)
  const [resultado, setResultado] = useState<Denuncia | null>(null)
  const [erro, setErro] = useState('')
  const [codigosGuardados, setCodigosGuardados] = useState<string[]>([])
  const [minhas, setMinhas] = useState<DenunciaComMensagem[]>([])
  const [carregandoMinhas, setCarregandoMinhas] = useState(false)

  useEffect(() => {
    if (!user?.id) return
    setCodigosGuardados(carregarCodigos(user.id))
    carregarMinhas()
  }, [user?.id])

  useEffect(() => {
    const estado = (location.state as { codigo?: string } | null)?.codigo
    if (estado) {
      setCodigo(estado)
      buscar(estado)
    }
  }, [])

  async function carregarMinhas() {
    setCarregandoMinhas(true)
    const { data } = await supabase.rpc('listar_minhas_denuncias')
    setMinhas(((data as DenunciaComMensagem[]) ?? []) as DenunciaComMensagem[])
    setCarregandoMinhas(false)
  }

  async function buscar(codigoBusca?: string) {
    const c = (codigoBusca ?? codigo).trim().toUpperCase()
    setErro('')
    setResultado(null)
    if (!c) {
      setErro('Introduza o código da denúncia')
      return
    }
    setLoading(true)
    try {
      const { data, error } = await supabase.rpc('buscar_denuncia_por_codigo', {
        codigo_procurado: c,
      })
      if (error) {
        setErro('Denúncia não encontrada com esse código')
        return
      }
      const linha = extrairLinha(data)
      const encontrada = linha && (linha.codigo || linha.codigo_denuncia || linha.status || linha.id)
      if (!encontrada) {
        setErro('Denúncia não encontrada com esse código')
        return
      }
      setResultado(linha as Denuncia)
    } catch {
      setErro('Denúncia não encontrada com esse código')
    } finally {
      setLoading(false)
    }
  }

  function abrirChat(denuncia: Denuncia) {
    navigate('/student/chat', { state: { denuncia } })
  }

  function remover(codigoRemover: string) {
    if (!user?.id) return
    setCodigosGuardados(removerCodigo(user.id, codigoRemover))
  }

  const conteudo = (
    <div className="mx-auto max-w-3xl space-y-6">
      <div>
        <h1 className="text-base font-semibold" style={{ color: colors.primario }}>
          Insira o código da denúncia
        </h1>
        <p className="mt-1 text-[13px]" style={{ color: colors.cinza }}>
          O código de acompanhamento está no comprovativo de submissão. Em denúncias anónimas
          funciona como credencial de acesso.
        </p>
      </div>

      <div className="flex gap-3">
        <div className="relative flex-1">
          <Hash
            className="absolute left-3 top-1/2 h-5 w-5 -translate-y-1/2"
            style={{ color: colors.cinza }}
          />
          <input
            value={codigo}
            onChange={(e) => setCodigo(e.target.value.toUpperCase())}
            onKeyDown={(e) => {
              if (e.key === 'Enter') buscar()
            }}
            placeholder="Código (ex: UNI-58392)"
            className="w-full rounded-lg border bg-white py-3 pl-10 pr-3 text-sm outline-none focus:ring-2"
            style={{ borderColor: colors.cinzaBorda }}
          />
        </div>
        <button
          onClick={() => buscar()}
          disabled={loading}
          className="flex items-center gap-2 rounded-lg px-5 text-white disabled:opacity-60"
          style={{ background: colors.primario }}
        >
          <Search className="h-4 w-4" />
          {loading ? 'A pesquisar...' : 'Pesquisar'}
        </button>
      </div>

      {erro && (
        <p className="text-sm" style={{ color: colors.vermelho }}>
          {erro}
        </p>
      )}

      {resultado && (
        <div
          className="rounded-xl border bg-white p-4"
          style={{ borderColor: colors.primarioClaro }}
        >
          <div className="flex items-start justify-between gap-3">
            <p
              className="text-xl font-extrabold tracking-wide"
              style={{ color: colors.primario }}
            >
              {resultado.codigo}
            </p>
            <StatusChip status={resultado.status} />
          </div>

          <div className="mt-3">
            <Timeline statusAtual={resultado.status} />
          </div>

          <div
            className="my-3 border-t"
            style={{ borderColor: colors.cinzaBorda }}
          />

          <DetalheLinha icon={Tags} label="Tipo" valor={displayCategoria(resultado)} />
          <DetalheLinha icon={Landmark} label="Faculdade" valor={resultado.faculdade} />
          <DetalheLinha icon={School} label="Curso" valor={resultado.curso ?? '—'} />
          <DetalheLinha
            icon={CalendarDays}
            label="Data do ocorrido"
            valor={formatarData(resultado.data_ocorrido)}
          />
          <DetalheLinha icon={MapPin} label="Local" valor={resultado.local_ocorrido ?? '—'} />
          <DetalheLinha
            icon={Flag}
            label="Data de envio"
            valor={formatarDataHora(resultado.created_at)}
          />

          {user ? (
            <button
              onClick={() => abrirChat(resultado)}
              className="mt-4 flex w-full items-center justify-center gap-2 rounded-xl px-6 py-3 font-semibold text-white"
              style={{ background: colors.primario }}
            >
              <MessageSquare className="h-4 w-4" />
              Conversar com a Comissão
            </button>
          ) : (
            <button
              onClick={() => navigate('/login')}
              className="mt-4 w-full rounded-xl border px-6 py-3 font-semibold"
              style={{ borderColor: colors.cinzaBorda, color: colors.primario }}
            >
              Entre na sua conta para conversar com a Comissão
            </button>
          )}
        </div>
      )}

      {user && codigosGuardados.length > 0 && (
        <div>
          <h2 className="text-base font-bold" style={{ color: colors.primario }}>
            Denúncias guardadas
          </h2>
          <p className="mt-1 text-xs" style={{ color: colors.cinza }}>
            Códigos das suas denúncias anónimas neste dispositivo. Clique para acompanhar;
            pode removê-los quando quiser.
          </p>
          <div className="mt-3 flex flex-wrap gap-2">
            {codigosGuardados.map((c) => (
              <span
                key={c}
                className="flex items-center gap-1.5 rounded-full border bg-white px-3 py-1.5"
                style={{ borderColor: colors.primarioClaro }}
              >
                <button
                  onClick={() => {
                    setCodigo(c)
                    buscar(c)
                  }}
                  className="flex items-center gap-1.5 text-sm font-bold tracking-wide"
                  style={{ color: colors.primario }}
                >
                  <Hash className="h-4 w-4" />
                  {c}
                </button>
                <button
                  onClick={() => remover(c)}
                  className="rounded-full p-0.5 hover:bg-gray-100"
                >
                  <X className="h-3.5 w-3.5" style={{ color: colors.cinza }} />
                </button>
              </span>
            ))}
          </div>
        </div>
      )}

      {user && (
        <div>
          <div className="mb-3 border-t" style={{ borderColor: colors.cinzaBorda }} />
          <h2 className="text-base font-bold" style={{ color: colors.primario }}>
            As suas denúncias
          </h2>

          {carregandoMinhas ? (
            <div className="py-8 text-center text-sm" style={{ color: colors.cinza }}>
              A carregar...
            </div>
          ) : minhas.length === 0 ? (
            <EmptyState
              icon={Inbox}
              mensagem="Nenhuma denúncia encontrada"
              subtitulo="As suas denúncias, identificadas e anónimas, aparecem aqui para acompanhamento."
            />
          ) : (
            <div className="mt-3 space-y-3">
              {minhas.map((d) => {
                const Icone = iconeStatus(d.status)
                const cor = corStatus(d.status)
                return (
                  <button
                    key={d.id}
                    onClick={() => abrirChat(d)}
                    className="flex w-full items-center gap-3 rounded-xl border bg-white p-3.5 text-left shadow-sm transition hover:shadow-md"
                    style={{ borderColor: colors.cinzaBorda }}
                  >
                    <span
                      className="flex h-11 w-11 shrink-0 items-center justify-center rounded-lg"
                      style={{ background: cor + '1A' }}
                    >
                      <Icone className="h-5 w-5" style={{ color: cor }} />
                    </span>
                    <span className="min-w-0 flex-1">
                      <span className="block truncate text-sm font-semibold">
                        {d.codigo} — {displayCategoria(d)}
                      </span>
                      <span className="block text-xs" style={{ color: colors.cinza }}>
                        {d.faculdade} • Enviada: {formatarData(d.created_at)}
                      </span>
                    </span>
                    <StatusChip status={d.status} />
                  </button>
                )
              })}
            </div>
          )}
        </div>
      )}
    </div>
  )

  if (!publico) return conteudo

  return (
    <div className="min-h-screen" style={{ background: colors.cinzaClaro }}>
      <div className="px-4 py-4" style={{ background: colors.primario }}>
        <div className="mx-auto flex max-w-3xl items-center justify-between">
          <button onClick={() => navigate('/')} className="text-white">
            Voltar
          </button>
          <div className="flex items-center gap-2 text-white">
            <img
              src="/logo-unilicungo.jpg"
              alt="Universidade Licungo"
              className="h-8 w-8 rounded-full object-cover"
            />
            <span className="font-semibold">VozUL — Acompanhar Denúncia</span>
          </div>
          <div className="w-12" />
        </div>
      </div>
      <div className="px-4 py-6">{conteudo}</div>
    </div>
  )
}
