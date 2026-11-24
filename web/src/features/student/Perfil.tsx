import { useEffect, useMemo, useState } from 'react'
import {
  BadgeCheck,
  BookOpen,
  Calendar,
  CheckCircle2,
  Hash,
  Landmark,
  Lock,
  Mail,
  Pencil,
  Phone,
  School,
  ShieldAlert,
  User,
  X,
} from 'lucide-react'
import { supabase } from '../../config/supabase'
import { colors } from '../../config/theme'
import { useAuth } from '../../contexts/AuthContext'
import { formatarData } from '../../lib/formatters'

interface Faculdade {
  id: string
  nome: string
}
interface Curso {
  id: string
  nome: string
  faculdade_id: string
}

function iniciais(nome: string | null): string {
  if (!nome) return '?'
  const partes = nome.trim().split(/\s+/)
  if (partes.length === 1) return partes[0].slice(0, 2).toUpperCase()
  return (partes[0][0] + partes[partes.length - 1][0]).toUpperCase()
}

function InfoItem({
  icon: Icone,
  label,
  valor,
}: {
  icon: typeof User
  label: string
  valor: string
}) {
  return (
    <div className="flex items-start gap-3 rounded-lg p-3" style={{ background: colors.cinzaClaro }}>
      <Icone className="mt-0.5 h-5 w-5 shrink-0" style={{ color: colors.cinza }} />
      <div className="min-w-0">
        <p className="text-[11px]" style={{ color: colors.cinza }}>
          {label}
        </p>
        <p className="break-words text-sm font-medium">{valor}</p>
      </div>
    </div>
  )
}

export default function Perfil() {
  const { profile, user, atualizarProfile } = useAuth()

  const [editar, setEditar] = useState(false)
  const [celular, setCelular] = useState('')
  const [faculdadeId, setFaculdadeId] = useState('')
  const [curso, setCurso] = useState('')
  const [faculdades, setFaculdades] = useState<Faculdade[]>([])
  const [cursos, setCursos] = useState<Curso[]>([])
  const [aGuardar, setAGuardar] = useState(false)
  const [feedback, setFeedback] = useState('')
  const [erroEdicao, setErroEdicao] = useState('')

  const [atual, setAtual] = useState('')
  const [nova, setNova] = useState('')
  const [confirmar, setConfirmar] = useState('')
  const [aAlterar, setAAlterar] = useState(false)
  const [feedbackSenha, setFeedbackSenha] = useState('')
  const [erroSenha, setErroSenha] = useState('')

  const temValidacao = Boolean(profile?.numero_validado_origem)

  const faculdadeNome = useMemo(() => {
    if (faculdadeId) return faculdades.find((f) => f.id === faculdadeId)?.nome ?? profile?.faculdade ?? ''
    return profile?.faculdade ?? ''
  }, [faculdadeId, faculdades, profile?.faculdade])

  useEffect(() => {
    if (!editar || !profile?.polo_id) return
    supabase
      .from('faculdades')
      .select('id, nome')
      .eq('polo_id', profile.polo_id)
      .eq('activo', true)
      .order('nome')
      .then(({ data }) => {
        const lista = (data as Faculdade[]) ?? []
        setFaculdades(lista)
        if (!faculdadeId && profile.faculdade) {
          const encontrada = lista.find((f) => f.nome === profile.faculdade)
          if (encontrada) setFaculdadeId(encontrada.id)
        }
      })
  }, [editar, profile?.polo_id])

  useEffect(() => {
    if (!editar || !faculdadeId) {
      setCursos([])
      return
    }
    supabase
      .from('cursos')
      .select('id, nome, faculdade_id')
      .eq('faculdade_id', faculdadeId)
      .eq('activo', true)
      .order('nome')
      .then(({ data }) => setCursos((data as Curso[]) ?? []))
  }, [editar, faculdadeId])

  function iniciarEdicao() {
    setCelular(profile?.celular ?? '')
    setFaculdadeId(profile?.faculdade_id ?? '')
    setCurso(profile?.curso ?? '')
    setFeedback('')
    setErroEdicao('')
    setEditar(true)
  }

  async function guardar() {
    setAGuardar(true)
    setErroEdicao('')
    setFeedback('')
    try {
      await atualizarProfile({
        celular: celular.trim() || null,
        faculdade: faculdadeNome || null,
        faculdade_id: faculdadeId || null,
        curso: curso || null,
      })
      setFeedback('Dados atualizados com sucesso.')
      setEditar(false)
    } catch {
      setErroEdicao('Não foi possível guardar as alterações. Tente novamente.')
    } finally {
      setAGuardar(false)
    }
  }

  async function alterarPalavraPasse() {
    setErroSenha('')
    setFeedbackSenha('')
    if (nova.length < 6) {
      setErroSenha('A nova palavra-passe deve ter pelo menos 6 caracteres.')
      return
    }
    if (nova !== confirmar) {
      setErroSenha('As palavras-passe não coincidem.')
      return
    }
    setAAlterar(true)
    try {
      if (profile?.email) {
        const { error: erroLogin } = await supabase.auth.signInWithPassword({
          email: profile.email,
          password: atual,
        })
        if (erroLogin) {
          setErroSenha('Palavra-passe atual incorreta.')
          return
        }
      }
      const { error } = await supabase.auth.updateUser({ password: nova })
      if (error) {
        setErroSenha('Não foi possível alterar a palavra-passe. Tente novamente.')
        return
      }
      setFeedbackSenha('Palavra-passe alterada com sucesso.')
      setAtual('')
      setNova('')
      setConfirmar('')
    } catch {
      setErroSenha('Não foi possível alterar a palavra-passe. Tente novamente.')
    } finally {
      setAAlterar(false)
    }
  }

  return (
    <div className="mx-auto max-w-3xl space-y-5">
      <div>
        <h1 className="text-xl font-bold" style={{ color: colors.primario }}>
          Perfil do Estudante
        </h1>
        <p className="mt-1 text-[13px]" style={{ color: colors.cinza }}>
          Visualize e atualize os seus dados cadastrais
        </p>
      </div>

      <div className="rounded-xl border bg-white p-5 shadow-sm" style={{ borderColor: colors.cinzaBorda }}>
        <div className="flex items-center gap-4">
          <div
            className="flex h-16 w-16 shrink-0 items-center justify-center rounded-full text-xl font-bold text-white"
            style={{
              background: `linear-gradient(135deg, ${colors.primarioClaro}, ${colors.primario})`,
            }}
          >
            {iniciais(profile?.nome_completo ?? null)}
          </div>
          <div className="min-w-0 flex-1">
            <p className="truncate text-lg font-bold" style={{ color: colors.primario }}>
              {profile?.nome_completo || 'Estudante'}
            </p>
            <p className="truncate text-[13px]" style={{ color: colors.cinza }}>
              {profile?.email || user?.email || '—'}
            </p>
            <span
              className="mt-1.5 inline-block rounded-full px-2.5 py-0.5 text-[11px] font-semibold"
              style={{ background: colors.primario + '1A', color: colors.primario }}
            >
              Estudante
            </span>
          </div>
          {!editar ? (
            <button
              onClick={iniciarEdicao}
              className="flex items-center gap-2 rounded-lg border px-4 py-2 text-sm font-semibold"
              style={{ borderColor: colors.primario, color: colors.primario }}
            >
              <Pencil className="h-4 w-4" />
              Editar
            </button>
          ) : (
            <button
              onClick={() => setEditar(false)}
              className="flex items-center gap-2 rounded-lg border px-4 py-2 text-sm font-semibold"
              style={{ borderColor: colors.cinzaBorda, color: colors.cinza }}
            >
              <X className="h-4 w-4" />
              Cancelar
            </button>
          )}
        </div>

        <div
          className="mt-4 flex items-start gap-3 rounded-lg p-3"
          style={{
            background: temValidacao ? colors.verdeClaro : colors.amareloClaro,
          }}
        >
          {temValidacao ? (
            <BadgeCheck className="mt-0.5 h-5 w-5 shrink-0" style={{ color: colors.verde }} />
          ) : (
            <ShieldAlert className="mt-0.5 h-5 w-5 shrink-0" style={{ color: colors.amarelo }} />
          )}
          <div className="min-w-0">
            <p className="text-sm font-semibold" style={{ color: temValidacao ? colors.verde : colors.amarelo }}>
              {temValidacao ? 'Número de estudante validado' : 'Número de estudante não validado'}
            </p>
            <p className="mt-0.5 text-xs" style={{ color: colors.cinza }}>
              {temValidacao
                ? [
                    profile?.numero_estudante,
                    profile?.numero_validado_origem,
                    profile?.numero_validado_estado,
                    profile?.numero_validado_em ? formatarData(profile.numero_validado_em) : null,
                  ]
                    .filter(Boolean)
                    .join(' • ')
                : 'A validação é feita pela Comissão de Ética com base no número/credencial submetido no registo.'}
            </p>
          </div>
        </div>
      </div>

      <div className="rounded-xl border bg-white p-5 shadow-sm" style={{ borderColor: colors.cinzaBorda }}>
        <h2 className="mb-3 flex items-center gap-2 text-[15px] font-bold" style={{ color: colors.primario }}>
          <User className="h-4 w-4" />
          Dados pessoais
        </h2>

        {editar ? (
          <div className="space-y-4">
            <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
              <div>
                <label className="mb-1 block text-xs font-medium" style={{ color: colors.cinza }}>
                  Nome completo
                </label>
                <input
                  value={profile?.nome_completo ?? ''}
                  disabled
                  className="w-full rounded-lg border bg-gray-50 px-3 py-2.5 text-sm"
                  style={{ borderColor: colors.cinzaBorda }}
                />
              </div>
              <div>
                <label className="mb-1 block text-xs font-medium" style={{ color: colors.cinza }}>
                  Número de estudante
                </label>
                <input
                  value={profile?.numero_estudante ?? ''}
                  disabled
                  className="w-full rounded-lg border bg-gray-50 px-3 py-2.5 text-sm"
                  style={{ borderColor: colors.cinzaBorda }}
                />
              </div>
              <div>
                <label className="mb-1 block text-xs font-medium" style={{ color: colors.cinza }}>
                  Celular
                </label>
                <input
                  value={celular}
                  onChange={(e) => setCelular(e.target.value)}
                  placeholder="+258 84 000 0000"
                  className="w-full rounded-lg border px-3 py-2.5 text-sm outline-none focus:ring-2"
                  style={{ borderColor: colors.cinzaBorda }}
                />
              </div>
              <div>
                <label className="mb-1 block text-xs font-medium" style={{ color: colors.cinza }}>
                  Email
                </label>
                <input
                  value={profile?.email ?? ''}
                  disabled
                  className="w-full rounded-lg border bg-gray-50 px-3 py-2.5 text-sm"
                  style={{ borderColor: colors.cinzaBorda }}
                />
              </div>
              <div>
                <label className="mb-1 block text-xs font-medium" style={{ color: colors.cinza }}>
                  Faculdade
                </label>
                <select
                  value={faculdadeId}
                  onChange={(e) => {
                    setFaculdadeId(e.target.value)
                    setCurso('')
                  }}
                  className="w-full rounded-lg border bg-white px-3 py-2.5 text-sm outline-none focus:ring-2"
                  style={{ borderColor: colors.cinzaBorda }}
                >
                  <option value="">Selecione a faculdade</option>
                  {faculdades.map((f) => (
                    <option key={f.id} value={f.id}>
                      {f.nome}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="mb-1 block text-xs font-medium" style={{ color: colors.cinza }}>
                  Curso
                </label>
                <select
                  value={curso}
                  onChange={(e) => setCurso(e.target.value)}
                  disabled={!faculdadeId}
                  className="w-full rounded-lg border bg-white px-3 py-2.5 text-sm outline-none focus:ring-2 disabled:bg-gray-50"
                  style={{ borderColor: colors.cinzaBorda }}
                >
                  <option value="">Selecione o curso</option>
                  {cursos.map((c) => (
                    <option key={c.id} value={c.nome}>
                      {c.nome}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            {erroEdicao && (
              <p className="text-xs" style={{ color: colors.vermelho }}>
                {erroEdicao}
              </p>
            )}

            <button
              onClick={guardar}
              disabled={aGuardar}
              className="flex items-center gap-2 rounded-lg px-6 py-2.5 text-sm font-semibold text-white disabled:opacity-60"
              style={{ background: colors.primario }}
            >
              <CheckCircle2 className="h-4 w-4" />
              {aGuardar ? 'A guardar...' : 'Guardar alterações'}
            </button>
          </div>
        ) : (
          <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
            <InfoItem icon={User} label="Nome completo" valor={profile?.nome_completo || '—'} />
            <InfoItem icon={Hash} label="Número de estudante" valor={profile?.numero_estudante || '—'} />
            <InfoItem icon={Phone} label="Celular" valor={profile?.celular || '—'} />
            <InfoItem icon={Mail} label="Email" valor={profile?.email || user?.email || '—'} />
            <InfoItem icon={Landmark} label="Faculdade" valor={profile?.faculdade || '—'} />
            <InfoItem icon={BookOpen} label="Curso" valor={profile?.curso || '—'} />
            <InfoItem icon={School} label="Campus" valor={profile?.polo_id ? 'Campus associado' : '—'} />
            <InfoItem
              icon={Calendar}
              label="Membro desde"
              valor={profile?.created_at ? formatarData(profile.created_at) : '—'}
            />
          </div>
        )}

        {feedback && (
          <p className="mt-3 text-xs font-medium" style={{ color: colors.verde }}>
            {feedback}
          </p>
        )}
      </div>

      <div className="rounded-xl border bg-white p-5 shadow-sm" style={{ borderColor: colors.cinzaBorda }}>
        <h2 className="mb-3 flex items-center gap-2 text-[15px] font-bold" style={{ color: colors.primario }}>
          <Lock className="h-4 w-4" />
          Alterar palavra-passe
        </h2>
        <div className="max-w-lg space-y-3">
          <div>
            <label className="mb-1 block text-xs font-medium" style={{ color: colors.cinza }}>
              Palavra-passe atual
            </label>
            <input
              type="password"
              value={atual}
              onChange={(e) => setAtual(e.target.value)}
              className="w-full rounded-lg border px-3 py-2.5 text-sm outline-none focus:ring-2"
              style={{ borderColor: colors.cinzaBorda }}
            />
          </div>
          <div>
            <label className="mb-1 block text-xs font-medium" style={{ color: colors.cinza }}>
              Nova palavra-passe
            </label>
            <input
              type="password"
              value={nova}
              onChange={(e) => setNova(e.target.value)}
              className="w-full rounded-lg border px-3 py-2.5 text-sm outline-none focus:ring-2"
              style={{ borderColor: colors.cinzaBorda }}
            />
          </div>
          <div>
            <label className="mb-1 block text-xs font-medium" style={{ color: colors.cinza }}>
              Confirmar nova palavra-passe
            </label>
            <input
              type="password"
              value={confirmar}
              onChange={(e) => setConfirmar(e.target.value)}
              className="w-full rounded-lg border px-3 py-2.5 text-sm outline-none focus:ring-2"
              style={{ borderColor: colors.cinzaBorda }}
            />
          </div>

          {erroSenha && (
            <p className="text-xs" style={{ color: colors.vermelho }}>
              {erroSenha}
            </p>
          )}
          {feedbackSenha && (
            <p className="text-xs font-medium" style={{ color: colors.verde }}>
              {feedbackSenha}
            </p>
          )}

          <button
            onClick={alterarPalavraPasse}
            disabled={aAlterar || !atual || !nova || !confirmar}
            className="flex items-center gap-2 rounded-lg px-6 py-2.5 text-sm font-semibold text-white disabled:opacity-60"
            style={{ background: colors.primario }}
          >
            <Lock className="h-4 w-4" />
            {aAlterar ? 'A atualizar...' : 'Atualizar palavra-passe'}
          </button>
        </div>
      </div>
    </div>
  )
}
