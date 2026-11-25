import { useNavigate } from 'react-router-dom'
import {
  ArrowLeftRight,
  Award,
  Crosshair,
  EyeOff,
  Flag,
  FolderOpen,
  GlobeLock,
  GraduationCap,
  Hash,
  Megaphone,
  MoreHorizontal,
  ShieldCheck,
  TriangleAlert,
  Users,
  UserX,
  type LucideIcon,
} from 'lucide-react'
import { colors } from '../../config/theme'
import { useAuth } from '../../contexts/AuthContext'

function getSaudacao() {
  const h = new Date().getHours()
  if (h < 12) return 'Bom dia'
  if (h < 18) return 'Boa tarde'
  return 'Boa noite'
}

const CATEGORIAS: { nome: string; icone: LucideIcon }[] = [
  { nome: 'Assédio sexual', icone: UserX },
  { nome: 'Corrupção', icone: ArrowLeftRight },
  { nome: 'Venda de notas', icone: GraduationCap },
  { nome: 'Discriminação', icone: Users },
  { nome: 'Violência verbal', icone: Megaphone },
  { nome: 'Ameaça', icone: TriangleAlert },
  { nome: 'Abuso de poder', icone: Award },
  { nome: 'Comportamento inadequado', icone: Flag },
  { nome: 'Outro', icone: MoreHorizontal },
]

const INFO_ANONIMATO = [
  { icone: EyeOff, texto: 'Nas denúncias anónimas, a autoria não é associada ao relato no sistema.' },
  { icone: GlobeLock, texto: 'A plataforma aplica controlos técnicos para proteger a confidencialidade dos dados.' },
  { icone: Hash, texto: 'Cada denúncia gera um código único para acompanhamento.' },
]

export default function StudentHome() {
  const navigate = useNavigate()
  const { profile } = useAuth()
  const nome = profile?.nome_completo || 'Estudante'
  const primeiro = nome.split(' ')[0]
  const saudacao = getSaudacao()

  return (
    <div className="space-y-6">
      <section
        className="rounded-2xl p-5 text-white"
        style={{
          background: `linear-gradient(135deg, ${colors.primario} 0%, ${colors.primarioClaro} 100%)`,
        }}
      >
        <Megaphone className="h-8 w-8 text-white" />
        <h1 className="mt-3 text-2xl font-bold">
          {saudacao}
          {primeiro ? `, ${primeiro}` : ''}!
        </h1>
        <p className="mt-1.5 text-sm text-white/75">
          A sua voz é importante. Denuncie com segurança.
        </p>
      </section>

      <section className="space-y-4">
        <button
          onClick={() => navigate('/student/denuncia')}
          className="flex w-full items-center gap-4 rounded-xl border bg-white p-5 text-left shadow-sm transition hover:shadow-md"
          style={{ borderColor: colors.cinzaBorda }}
        >
          <span
            className="flex h-13 w-13 shrink-0 items-center justify-center rounded-xl"
            style={{ width: 52, height: 52, background: colors.primarioClaro + '26' }}
          >
            <TriangleAlert className="h-7 w-7" style={{ color: colors.primario }} />
          </span>
          <span className="flex-1">
            <span className="block text-base font-bold" style={{ color: colors.primario }}>
              Fazer Denúncia
            </span>
            <span className="block text-[13px]" style={{ color: colors.cinza }}>
              Anónima ou identificada
            </span>
          </span>
          <span className="text-xl" style={{ color: colors.cinza }}>
            ›
          </span>
        </button>

        <button
          onClick={() => navigate('/student/acompanhamento')}
          className="flex w-full items-center gap-4 rounded-xl border bg-white p-5 text-left shadow-sm transition hover:shadow-md"
          style={{ borderColor: colors.cinzaBorda }}
        >
          <span
            className="flex shrink-0 items-center justify-center rounded-xl"
            style={{ width: 52, height: 52, background: colors.verde + '1A' }}
          >
            <Crosshair className="h-7 w-7" style={{ color: colors.verde }} />
          </span>
          <span className="flex-1">
            <span className="block text-base font-bold" style={{ color: colors.verde }}>
              Acompanhar Denúncia
            </span>
            <span className="block text-[13px]" style={{ color: colors.cinza }}>
              Use o código UNI-XXXXX
            </span>
          </span>
          <span className="text-xl" style={{ color: colors.cinza }}>
            ›
          </span>
        </button>

        <button
          onClick={() => navigate('/student/acompanhamento')}
          className="flex w-full items-center gap-4 rounded-xl border bg-white p-5 text-left shadow-sm transition hover:shadow-md"
          style={{ borderColor: colors.cinzaBorda }}
        >
          <span
            className="flex shrink-0 items-center justify-center rounded-xl"
            style={{ width: 52, height: 52, background: colors.cinzaClaro }}
          >
            <FolderOpen className="h-7 w-7" style={{ color: colors.cinza }} />
          </span>
          <span className="flex-1">
            <span className="block text-base font-bold" style={{ color: colors.cinza }}>
              Minhas Denúncias
            </span>
            <span className="block text-[13px]" style={{ color: colors.cinza }}>
              Ver o estado de todas as suas denúncias
            </span>
          </span>
          <span className="text-xl" style={{ color: colors.cinza }}>
            ›
          </span>
        </button>
      </section>

      <section>
        <h2 className="mb-3 text-base font-semibold" style={{ color: colors.primario }}>
          Tipos de denúncias
        </h2>
        <div className="grid grid-cols-3 gap-3 sm:grid-cols-4 lg:grid-cols-6 xl:grid-cols-9">
          {CATEGORIAS.map(({ nome, icone: Icone }) => (
            <button
              key={nome}
              onClick={() => navigate(`/student/denuncia?categoria=${encodeURIComponent(nome)}`)}
              className="flex flex-col items-center justify-center gap-2 rounded-xl border bg-white p-3 text-center transition hover:shadow"
              style={{ borderColor: colors.cinzaBorda }}
            >
              <Icone className="h-6 w-6" style={{ color: colors.primario }} />
              <span
                className="line-clamp-2 text-[11px] font-semibold leading-tight"
                style={{ color: colors.primario }}
              >
                {nome}
              </span>
            </button>
          ))}
        </div>
      </section>

      <section
        className="rounded-xl border bg-white p-5"
        style={{ borderColor: colors.verde + '4D' }}
      >
        <div className="mb-3 flex items-center gap-2.5">
          <ShieldCheck className="h-5 w-5" style={{ color: colors.verde }} />
          <h2 className="text-[15px] font-bold" style={{ color: colors.verde }}>
            O seu anonimato está protegido
          </h2>
        </div>
        <div className="space-y-2">
          {INFO_ANONIMATO.map(({ icone: Icone, texto }) => (
            <div key={texto} className="flex items-start gap-2">
              <Icone className="mt-0.5 h-4 w-4 shrink-0" style={{ color: colors.verde }} />
              <p className="text-[13px]" style={{ color: colors.cinza }}>
                {texto}
              </p>
            </div>
          ))}
        </div>
      </section>
    </div>
  )
}
