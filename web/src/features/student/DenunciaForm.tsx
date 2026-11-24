import { useEffect, useMemo, useState, type ChangeEvent, type FormEvent } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import {
  BadgeCheck,
  Bell,
  CalendarDays,
  CheckCircle2,
  FileText,
  IdCard,
  Info,
  Landmark,
  MessageSquare,
  Paperclip,
  Plus,
  Send,
  Shield,
  Tags,
  UserRound,
  X,
} from 'lucide-react'
import { supabase } from '../../config/supabase'
import { colors } from '../../config/theme'
import { useAuth } from '../../contexts/AuthContext'
import { dataIsoHoje, formatarTamanho } from '../../lib/formatters'
import { guardarCodigo } from '../../lib/codigosGuardados'
import SectionCard from '../../components/ui/SectionCard'
import type { Denuncia } from '../../lib/types'

interface Polo {
  id: string
  nome: string
  cidade: string
  principal: boolean
}
interface Faculdade {
  id: string
  nome: string
  polo_id: string
}
interface Curso {
  id: string
  nome: string
  faculdade_id: string
}

const CATEGORIAS = [
  'Assédio sexual',
  'Corrupção',
  'Venda de notas',
  'Discriminação',
  'Violência verbal',
  'Ameaça',
  'Abuso de poder',
  'Comportamento inadequado',
  'Outro',
]

const TIPOS_DENUNCIADO = ['Docente', 'Estudante', 'Funcionário']
const MAX_FICHEIROS = 5
const MAX_TAMANHO_MB = 25

function normalizarTipo(tipo: string): string {
  const t = tipo.toLowerCase().trim()
  return t === 'funcionário' ? 'funcionario' : t
}

function extrairLinha(data: unknown): Record<string, any> | null {
  if (Array.isArray(data)) return (data[0] as Record<string, any>) ?? null
  if (data && typeof data === 'object') return data as Record<string, any>
  return null
}

export default function DenunciaForm() {
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()
  const { user, profile } = useAuth()

  const categoriaInicial = useMemo(() => {
    const valor = searchParams.get('categoria')
    return valor && CATEGORIAS.includes(valor) ? valor : ''
  }, [searchParams])

  const [polos, setPolos] = useState<Polo[]>([])
  const [faculdades, setFaculdades] = useState<Faculdade[]>([])
  const [cursos, setCursos] = useState<Curso[]>([])
  const [locais, setLocais] = useState<string[]>([])

  const [poloId, setPoloId] = useState('')
  const [faculdadeId, setFaculdadeId] = useState('')
  const [cursoId, setCursoId] = useState('')

  const [categoria, setCategoria] = useState(categoriaInicial)
  const [categoriaOutro, setCategoriaOutro] = useState('')
  const [denunciadoTipo, setDenunciadoTipo] = useState('')
  const [denunciadoNome, setDenunciadoNome] = useState('')
  const [denunciadoNumero, setDenunciadoNumero] = useState('')
  const [denunciadoCelular, setDenunciadoCelular] = useState('')
  const [descricao, setDescricao] = useState('')
  const [anonima, setAnonima] = useState(true)
  const [emailNotif, setEmailNotif] = useState('')
  const [dataOcorrido, setDataOcorrido] = useState('')
  const [localOcorrido, setLocalOcorrido] = useState('')
  const [localOutro, setLocalOutro] = useState('')

  const [ficheiros, setFicheiros] = useState<File[]>([])
  const [loading, setLoading] = useState(false)
  const [sucesso, setSucesso] = useState<{ denuncia: Denuncia } | null>(null)

  useEffect(() => {
    supabase
      .from('polos')
      .select('id,nome,cidade,principal')
      .eq('activo', true)
      .order('principal', { ascending: false })
      .order('nome')
      .then(({ data }) => {
        const lista = (data as Polo[]) ?? []
        setPolos(lista)
        if (lista.length) {
          const preferido = profile?.polo_id && lista.some((p) => p.id === profile.polo_id)
          setPoloId(preferido ? (profile!.polo_id as string) : lista[0].id)
        }
      })
  }, [profile?.polo_id])

  useEffect(() => {
    setFaculdadeId('')
    setCursoId('')
    setLocalOcorrido('')
    setLocalOutro('')
    if (!poloId) {
      setFaculdades([])
      setCursos([])
      setLocais([])
      return
    }
    supabase
      .from('faculdades')
      .select('id,nome,polo_id')
      .eq('polo_id', poloId)
      .eq('activo', true)
      .order('nome')
      .then(({ data }) => setFaculdades((data as Faculdade[]) ?? []))
    supabase
      .from('locais_ocorrencia')
      .select('nome')
      .eq('polo_id', poloId)
      .eq('activo', true)
      .order('ordem')
      .order('nome')
      .then(({ data }) => setLocais(((data as { nome: string }[]) ?? []).map((l) => l.nome)))
  }, [poloId])

  useEffect(() => {
    setCursoId('')
    if (!faculdadeId) {
      setCursos([])
      return
    }
    supabase
      .from('cursos')
      .select('id,nome,faculdade_id')
      .eq('faculdade_id', faculdadeId)
      .eq('activo', true)
      .order('nome')
      .then(({ data }) => setCursos((data as Curso[]) ?? []))
  }, [faculdadeId])

  function adicionarFicheiros(e: ChangeEvent<HTMLInputElement>) {
    const selecionados = Array.from(e.target.files ?? [])
    const validos: File[] = []
    for (const f of selecionados) {
      if (f.size > MAX_TAMANHO_MB * 1024 * 1024) {
        alert(`Ficheiro excede ${MAX_TAMANHO_MB}MB: ${f.name}`)
        continue
      }
      validos.push(f)
    }
    setFicheiros((prev) => [...prev, ...validos].slice(0, MAX_FICHEIROS))
    e.target.value = ''
  }

  function localFinal(): string {
    if (locais.length === 0 || localOcorrido === 'Outro') return localOutro.trim()
    return localOcorrido
  }

  async function carregarEvidencias(denunciaId: number) {
    for (let i = 0; i < ficheiros.length; i++) {
      const ficheiro = ficheiros[i]
      const extensao = ficheiro.name.split('.').pop()?.toLowerCase() ?? 'bin'
      const caminho = `evidencias/${denunciaId}_${Date.now()}_${i}_${ficheiro.name}`
      const { error } = await supabase.storage.from('denuncias').upload(caminho, ficheiro)
      if (error) throw error
      await supabase.from('denuncias_evidencias').insert({
        denuncia_id: denunciaId,
        file_url: caminho,
        file_name: ficheiro.name,
        file_type: extensao,
        file_size: ficheiro.size,
      })
    }
  }

  async function submit(e: FormEvent) {
    e.preventDefault()
    if (!poloId) return alert('Selecione o Campus / Delegação')
    if (!faculdadeId) return alert('Selecione a Faculdade')
    if (!categoria) return alert('Selecione o tipo de denúncia')
    if (categoria === 'Outro' && !categoriaOutro.trim()) return alert('Descreva o tipo de denúncia')
    if (denunciadoTipo && !denunciadoNome.trim()) {
      return alert(`Indique o nome do ${denunciadoTipo.toLowerCase()}`)
    }
    if (!dataOcorrido) return alert('Selecione a data do ocorrido')
    if (!localFinal()) return alert('Indique o local do ocorrido')
    if (!descricao.trim()) return alert('Descreva o ocorrido')

    setLoading(true)
    try {
      const faculdade = faculdades.find((f) => f.id === faculdadeId)
      const curso = cursos.find((c) => c.id === cursoId)

      const { data, error } = await supabase.rpc('criar_denuncia', {
        categoria: categoria,
        categoria_custom: categoria === 'Outro' ? categoriaOutro.trim() : null,
        descricao: descricao.trim(),
        denunciado_tipo: denunciadoTipo ? normalizarTipo(denunciadoTipo) : null,
        denunciado_nome: denunciadoTipo ? denunciadoNome.trim() : null,
        denunciado_numero: denunciadoNumero.trim() || null,
        denunciado_celular: denunciadoCelular.trim() || null,
        faculdade: faculdade?.nome ?? '',
        curso: curso?.nome ?? null,
        local_ocorrido: localFinal(),
        data_ocorrido: dataOcorrido,
        anonima,
        estudante_id: anonima ? null : (user?.id ?? null),
        tem_provas: ficheiros.length > 0,
        email_notificacao: anonima && emailNotif.trim() ? emailNotif.trim() : null,
        p_polo_id: poloId,
      })
      if (error) throw error

      const linha = extrairLinha(data)
      const codigo = linha?.codigo ?? linha?.codigo_denuncia
      if (!linha || !codigo) {
        throw new Error('Não foi possível obter o código da denúncia. Tente novamente.')
      }

      if (ficheiros.length > 0 && linha.id) {
        await carregarEvidencias(Number(linha.id))
      }

      if (anonima && user?.id) guardarCodigo(user.id, String(codigo))

      const denuncia: Denuncia = {
        id: Number(linha.id),
        codigo: String(codigo),
        categoria: linha.categoria ?? categoria,
        categoria_custom: linha.categoria_custom ?? null,
        descricao: linha.descricao ?? descricao.trim(),
        denunciado_tipo: linha.denunciado_tipo ?? null,
        denunciado_nome: linha.denunciado_nome ?? null,
        denunciado_numero: linha.denunciado_numero ?? null,
        denunciado_celular: linha.denunciado_celular ?? null,
        faculdade: linha.faculdade ?? faculdade?.nome ?? '',
        polo_id: linha.polo_id ?? poloId,
        curso: linha.curso ?? curso?.nome ?? null,
        local_ocorrido: linha.local_ocorrido ?? localFinal(),
        data_ocorrido: linha.data_ocorrido ?? dataOcorrido,
        status: linha.status ?? 'Recebida',
        anonima: linha.anonima ?? anonima,
        estudante_id: linha.estudante_id ?? null,
        tem_provas: linha.tem_provas ?? ficheiros.length > 0,
        admin_responsavel: linha.admin_responsavel ?? null,
        created_at: linha.created_at ?? new Date().toISOString(),
        updated_at: linha.updated_at ?? new Date().toISOString(),
      }

      setSucesso({ denuncia })
    } catch (err: any) {
      alert(err?.message ?? 'Erro ao enviar denúncia')
    } finally {
      setLoading(false)
    }
  }

  if (sucesso) {
    const { denuncia } = sucesso
    return (
      <div className="mx-auto flex max-w-xl flex-col items-center px-4 py-10 text-center">
        <div
          className="flex items-center justify-center rounded-full"
          style={{ width: 110, height: 110, background: colors.verdeClaro }}
        >
          <CheckCircle2 className="h-16 w-16" style={{ color: colors.verde }} />
        </div>
        <h1 className="mt-6 text-2xl font-bold" style={{ color: colors.primario }}>
          Denúncia recebida com sucesso!
        </h1>
        <p className="mt-3 text-sm" style={{ color: colors.cinza }}>
          {denuncia.anonima
            ? 'A sua denúncia foi enviada anonimamente.'
            : 'A sua denúncia foi enviada.'}
        </p>

        <div
          className="mt-8 w-full rounded-2xl border bg-white p-5"
          style={{ borderColor: colors.primarioClaro }}
        >
          <p className="text-[13px]" style={{ color: colors.cinza }}>
            Guarde este código para acompanhar:
          </p>
          <div
            className="mx-auto mt-3 inline-block rounded-xl px-5 py-3"
            style={{ background: colors.primario }}
          >
            <p className="text-2xl font-extrabold tracking-[3px] text-white">{denuncia.codigo}</p>
          </div>
          <p className="mt-3 text-xs" style={{ color: colors.cinza }}>
            {denuncia.anonima
              ? 'Este código ficou guardado no separador "Acompanhar" para consultar depois.'
              : 'Pode acompanhar esta denúncia no separador "Acompanhar".'}
          </p>
        </div>

        <button
          onClick={() => navigate('/student/chat', { state: { denuncia } })}
          className="mt-8 flex w-full items-center justify-center gap-2 rounded-xl px-6 py-3 font-semibold text-white"
          style={{ background: colors.primario }}
        >
          <MessageSquare className="h-5 w-5" />
          Conversar com a Comissão
        </button>
        <button
          onClick={() => navigate('/student')}
          className="mt-3 flex w-full items-center justify-center gap-2 rounded-xl border px-6 py-3 font-semibold"
          style={{ borderColor: colors.cinzaBorda, color: colors.primario }}
        >
          Voltar ao Início
        </button>
      </div>
    )
  }

  const inputStyle = { borderColor: colors.cinzaBorda }
  const inputClass = 'w-full rounded-lg border bg-white p-2.5 text-sm outline-none focus:ring-2'
  const labelClass = 'mb-1 block text-sm font-medium'

  return (
    <div className="mx-auto max-w-3xl space-y-5">
      <div>
        <h1 className="text-2xl font-semibold" style={{ color: colors.primario }}>
          Fazer Denúncia
        </h1>
        <p className="mt-1 text-sm" style={{ color: colors.cinza }}>
          Preencha os campos obrigatórios para registar a sua denúncia.
        </p>
      </div>

      <form onSubmit={submit} className="space-y-5">
        <div
          className="rounded-xl border bg-white p-4"
          style={{ borderColor: anonima ? colors.verde : colors.primario }}
        >
          <div className="mb-3 flex items-center gap-2.5">
            {anonima ? (
              <Shield className="h-5 w-5" style={{ color: colors.verde }} />
            ) : (
              <BadgeCheck className="h-5 w-5" style={{ color: colors.primario }} />
            )}
            <h2 className="text-[15px] font-bold">Modo da denúncia</h2>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <button
              type="button"
              onClick={() => setAnonima(true)}
              className="flex flex-col items-center gap-2 rounded-xl border p-3"
              style={{
                borderColor: anonima ? colors.verde : colors.cinzaBorda,
                borderWidth: anonima ? 2 : 1,
                background: anonima ? colors.verde + '14' : colors.cinzaClaro,
              }}
            >
              <Shield className="h-7 w-7" style={{ color: colors.verde }} />
              <span
                className="text-sm font-bold"
                style={{ color: anonima ? colors.verde : colors.cinza }}
              >
                Anónima
              </span>
              <span className="text-center text-[11px]" style={{ color: colors.cinza }}>
                Sem revelar identidade
              </span>
            </button>
            <button
              type="button"
              onClick={() => setAnonima(false)}
              className="flex flex-col items-center gap-2 rounded-xl border p-3"
              style={{
                borderColor: !anonima ? colors.primario : colors.cinzaBorda,
                borderWidth: !anonima ? 2 : 1,
                background: !anonima ? colors.primarioClaro + '14' : colors.cinzaClaro,
              }}
            >
              <IdCard className="h-7 w-7" style={{ color: colors.primario }} />
              <span
                className="text-sm font-bold"
                style={{ color: !anonima ? colors.primario : colors.cinza }}
              >
                Identificada
              </span>
              <span className="text-center text-[11px]" style={{ color: colors.cinza }}>
                Visível à Comissão
              </span>
            </button>
          </div>
        </div>

        <SectionCard titulo="Tipo de denúncia" icon={Tags}>
          <label className={labelClass}>Selecione o tipo *</label>
          <select
            value={categoria}
            onChange={(e) => {
              setCategoria(e.target.value)
              if (e.target.value !== 'Outro') setCategoriaOutro('')
            }}
            className={inputClass}
            style={inputStyle}
          >
            <option value="">Selecionar...</option>
            {CATEGORIAS.map((c) => (
              <option key={c} value={c}>
                {c}
              </option>
            ))}
          </select>
          {categoria === 'Outro' && (
            <input
              value={categoriaOutro}
              onChange={(e) => setCategoriaOutro(e.target.value)}
              placeholder="Descreva o tipo de denúncia"
              className={inputClass + ' mt-3'}
              style={inputStyle}
            />
          )}
        </SectionCard>

        <SectionCard titulo="Campus, Faculdade e Curso" icon={Landmark}>
          <label className={labelClass}>Campus / delegação *</label>
          <select
            value={poloId}
            onChange={(e) => setPoloId(e.target.value)}
            className={inputClass}
            style={inputStyle}
          >
            <option value="">Selecionar...</option>
            {polos.map((p) => (
              <option key={p.id} value={p.id}>
                {p.nome} — {p.cidade}
              </option>
            ))}
          </select>

          <label className={labelClass + ' mt-3'}>Faculdade *</label>
          <select
            value={faculdadeId}
            onChange={(e) => setFaculdadeId(e.target.value)}
            disabled={!poloId}
            className={inputClass + ' disabled:bg-gray-50'}
            style={inputStyle}
          >
            <option value="">Selecionar...</option>
            {faculdades.map((f) => (
              <option key={f.id} value={f.id}>
                {f.nome}
              </option>
            ))}
          </select>

          <label className={labelClass + ' mt-3'}>Curso</label>
          <select
            value={cursoId}
            onChange={(e) => setCursoId(e.target.value)}
            disabled={!faculdadeId}
            className={inputClass + ' disabled:bg-gray-50'}
            style={inputStyle}
          >
            <option value="">Selecionar...</option>
            {cursos.map((c) => (
              <option key={c.id} value={c.id}>
                {c.nome}
              </option>
            ))}
          </select>
        </SectionCard>

        <SectionCard titulo="Quem é o denunciado?" icon={UserRound}>
          <label className={labelClass}>Categoria do denunciado</label>
          <select
            value={denunciadoTipo}
            onChange={(e) => {
              setDenunciadoTipo(e.target.value)
              setDenunciadoNome('')
              setDenunciadoNumero('')
              setDenunciadoCelular('')
            }}
            className={inputClass}
            style={inputStyle}
          >
            <option value="">Selecionar...</option>
            {TIPOS_DENUNCIADO.map((t) => (
              <option key={t} value={t}>
                {t}
              </option>
            ))}
          </select>

          {denunciadoTipo === 'Docente' && (
            <div className="mt-3 space-y-3">
              <input
                value={denunciadoNome}
                onChange={(e) => setDenunciadoNome(e.target.value)}
                placeholder="Nome do docente"
                className={inputClass}
                style={inputStyle}
              />
              <input
                value={denunciadoNumero}
                onChange={(e) => setDenunciadoNumero(e.target.value)}
                placeholder="Número de funcionário"
                className={inputClass}
                style={inputStyle}
              />
            </div>
          )}

          {denunciadoTipo === 'Estudante' && (
            <div className="mt-3 space-y-3">
              <input
                value={denunciadoNome}
                onChange={(e) => setDenunciadoNome(e.target.value)}
                placeholder="Nome do estudante"
                className={inputClass}
                style={inputStyle}
              />
              <input
                value={denunciadoNumero}
                onChange={(e) => setDenunciadoNumero(e.target.value)}
                placeholder="Número de estudante (opcional)"
                className={inputClass}
                style={inputStyle}
              />
              <input
                value={denunciadoCelular}
                onChange={(e) => setDenunciadoCelular(e.target.value)}
                placeholder="Celular do estudante (opcional)"
                className={inputClass}
                style={inputStyle}
              />
            </div>
          )}

          {denunciadoTipo === 'Funcionário' && (
            <div className="mt-3 space-y-3">
              <input
                value={denunciadoNome}
                onChange={(e) => setDenunciadoNome(e.target.value)}
                placeholder="Nome do funcionário"
                className={inputClass}
                style={inputStyle}
              />
              <input
                value={denunciadoNumero}
                onChange={(e) => setDenunciadoNumero(e.target.value)}
                placeholder="Número de funcionário"
                className={inputClass}
                style={inputStyle}
              />
            </div>
          )}
        </SectionCard>

        <SectionCard titulo="Descrição do ocorrido" icon={FileText}>
          <textarea
            value={descricao}
            onChange={(e) => setDescricao(e.target.value)}
            rows={6}
            placeholder="Descreva detalhadamente o que aconteceu..."
            className={inputClass}
            style={inputStyle}
          />
        </SectionCard>

        {anonima && (
          <SectionCard titulo="Notificações por email (opcional)" icon={Bell}>
            <label className={labelClass}>Email para receber atualizações</label>
            <input
              type="email"
              value={emailNotif}
              onChange={(e) => setEmailNotif(e.target.value)}
              placeholder="exemplo@email.com"
              className={inputClass}
              style={inputStyle}
            />
            <p className="mt-2 text-xs" style={{ color: colors.cinza }}>
              Será notificado por email quando o estado da denúncia mudar ou a Comissão
              responder. Em modo anónimo, este email não fica associado à sua identidade.
            </p>
          </SectionCard>
        )}

        <SectionCard titulo="Data e local do ocorrido" icon={CalendarDays}>
          <label className={labelClass}>Data do ocorrido *</label>
          <input
            type="date"
            value={dataOcorrido}
            max={dataIsoHoje()}
            onChange={(e) => setDataOcorrido(e.target.value)}
            className={inputClass}
            style={inputStyle}
          />

          <label className={labelClass + ' mt-3'}>Local do ocorrido *</label>
          {locais.length > 0 ? (
            <>
              <select
                value={localOcorrido}
                onChange={(e) => {
                  setLocalOcorrido(e.target.value)
                  if (e.target.value !== 'Outro') setLocalOutro('')
                }}
                className={inputClass}
                style={inputStyle}
              >
                <option value="">Selecionar...</option>
                {[...locais, 'Outro'].map((l) => (
                  <option key={l} value={l}>
                    {l}
                  </option>
                ))}
              </select>
              {localOcorrido === 'Outro' && (
                <input
                  value={localOutro}
                  onChange={(e) => setLocalOutro(e.target.value)}
                  placeholder="Descreva o local"
                  className={inputClass + ' mt-3'}
                  style={inputStyle}
                />
              )}
            </>
          ) : (
            <input
              value={localOutro}
              onChange={(e) => setLocalOutro(e.target.value)}
              placeholder="Descreva o local, ex.: Campus X — Bloco Y"
              className={inputClass}
              style={inputStyle}
            />
          )}
        </SectionCard>

        <SectionCard titulo="Evidências (provas)" icon={Paperclip}>
          {ficheiros.length === 0 && (
            <div
              className="mb-3 flex items-start gap-2 rounded-lg p-3"
              style={{ background: colors.amareloClaro }}
            >
              <Info className="mt-0.5 h-4 w-4 shrink-0" style={{ color: colors.amarelo }} />
              <p className="text-xs" style={{ color: colors.amarelo }}>
                Sem provas anexadas. A Comissão será informada que não há evidências.
              </p>
            </div>
          )}

          {ficheiros.length > 0 && (
            <div className="mb-3 flex flex-wrap gap-2">
              {ficheiros.map((f, i) => (
                <div
                  key={i}
                  className="flex items-center gap-2 rounded-lg border px-3 py-2 text-xs"
                  style={{ borderColor: colors.cinzaBorda, background: colors.cinzaClaro }}
                >
                  <Paperclip className="h-4 w-4" style={{ color: colors.primario }} />
                  <span className="max-w-40 truncate">{f.name}</span>
                  <span style={{ color: colors.cinza }}>{formatarTamanho(f.size)}</span>
                  <button
                    type="button"
                    onClick={() => setFicheiros((prev) => prev.filter((_, idx) => idx !== i))}
                    className="rounded-full p-0.5"
                    style={{ background: colors.vermelho }}
                  >
                    <X className="h-3 w-3 text-white" />
                  </button>
                </div>
              ))}
            </div>
          )}

          {ficheiros.length < MAX_FICHEIROS && (
            <label
              className="flex cursor-pointer items-center justify-center gap-2 rounded-lg border-2 border-dashed p-4 text-sm"
              style={{ borderColor: colors.cinzaBorda, color: colors.primario }}
            >
              <Plus className="h-4 w-4" />
              Adicionar evidência
              <input
                type="file"
                multiple
                accept="image/*,.pdf,audio/*,video/*"
                onChange={adicionarFicheiros}
                className="hidden"
              />
            </label>
          )}

          <p className="mt-2 text-[11px]" style={{ color: colors.cinza }}>
            Imagens, PDFs, áudios e vídeos. Máx. {MAX_FICHEIROS} ficheiros de {MAX_TAMANHO_MB}MB.
          </p>
        </SectionCard>

        <div className="flex flex-col items-center gap-3">
          <button
            disabled={loading}
            className="flex w-full items-center justify-center gap-2 rounded-xl px-8 py-3 font-semibold text-white disabled:opacity-60"
            style={{ background: colors.primario }}
          >
            <Send className="h-4 w-4" />
            {loading ? 'A enviar a sua denúncia...' : 'Enviar Denúncia'}
          </button>
          <p className="text-center text-xs" style={{ color: colors.cinza }}>
            Ao enviar, confirma que esta denúncia é verdadeira e feita de boa-fé. Denúncias
            falsas podem ter consequências.
          </p>
        </div>
      </form>
    </div>
  )
}
