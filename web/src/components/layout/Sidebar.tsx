import { NavLink, useNavigate } from 'react-router-dom'
import { Home, MessageSquare, Crosshair, User, LogOut, FilePlus2 } from 'lucide-react'
import { colors } from '../../config/theme'
import { useAuth } from '../../contexts/AuthContext'
import { useNaoLidas } from '../../lib/useNaoLidas'

const items = [
  { to: '/student', label: 'Início', icon: Home },
  { to: '/student/mensagens', label: 'Mensagens', icon: MessageSquare },
  { to: '/student/acompanhamento', label: 'Acompanhar', icon: Crosshair },
  { to: '/student/perfil', label: 'Perfil', icon: User },
]

type Props = {
  onNavigate?: () => void
  className?: string
}

export default function Sidebar({ onNavigate, className }: Props) {
  const { signOut, profile } = useAuth()
  const navigate = useNavigate()
  const naoLidas = useNaoLidas()
  const nome = profile?.nome_completo || profile?.email || 'Estudante'

  return (
    <aside
      className={'flex h-full w-72 flex-col ' + (className ?? '')}
      style={{ background: colors.primario }}
    >
      <div className="flex items-center gap-3 px-6 py-6">
        <img
          src="/logo-unilicungo.jpg"
          alt="Universidade Licungo"
          className="h-10 w-10 rounded-full object-cover"
        />
        <div>
          <p className="text-lg font-bold text-white">VozUL</p>
          <p className="text-xs text-white/80">Universidade Licungo</p>
        </div>
      </div>

      <div className="px-4 pb-4">
        <button
          onClick={() => {
            navigate('/student/denuncia')
            onNavigate?.()
          }}
          className="flex w-full items-center justify-center gap-2 rounded-xl bg-white px-4 py-3 font-semibold shadow-sm transition hover:bg-white/90"
          style={{ color: colors.primario }}
        >
          <FilePlus2 className="h-5 w-5" />
          Fazer Denúncia
        </button>
      </div>

      <nav className="flex-1 space-y-1 px-3">
        {items.map((item) => {
          const Icon = item.icon
          return (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.to === '/student'}
              onClick={onNavigate}
              className={({ isActive }) =>
                'flex items-center gap-3 rounded-lg px-3 py-2.5 transition ' +
                (isActive
                  ? 'bg-white/15 text-white'
                  : 'text-white/80 hover:bg-white/10 hover:text-white')
              }
            >
              <Icon className="h-5 w-5" />
              <span className="font-medium">{item.label}</span>
              {item.to === '/student/mensagens' && naoLidas > 0 && (
                <span
                  className="ml-auto rounded-full px-2 py-0.5 text-xs font-bold text-white"
                  style={{ background: colors.vermelho }}
                >
                  {naoLidas}
                </span>
              )}
            </NavLink>
          )
        })}
      </nav>

      <div className="border-t border-white/10 px-4 py-4">
        <div className="mb-2 truncate text-sm text-white/90">{nome}</div>
        <button
          onClick={signOut}
          className="flex items-center gap-2 text-white/80 hover:text-white"
        >
          <LogOut className="h-4 w-4" />
          <span>Sair</span>
        </button>
      </div>
    </aside>
  )
}
