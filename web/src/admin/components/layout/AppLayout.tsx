import { useCallback } from 'react'
import {
  Bell,
  FileText,
  History,
  Inbox,
  LogOut,
  Menu,
  MessageSquare,
  Settings,
  Shield,
  UserCircle,
  UserCog,
} from 'lucide-react'
import { NavLink, Outlet, useLocation, useNavigate } from 'react-router-dom'
import {
  Avatar,
  AvatarFallback,
  Button,
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
  Separator,
  Sheet,
  SheetContent,
  SheetTrigger,
} from '../../components/ui'
import { useAuth } from '../../lib/auth'
import { cn } from '../../../lib/utils'
import { rotuloRole, siglaNome } from '../../lib/format'
import { NotificationsBell } from '../../features/notificacoes/NotificationsBell'

const NAV = [
  { to: '/admin/dashboard', label: 'Dashboard', icon: Bell },
  { to: '/admin/denuncias', label: 'Denúncias', icon: Inbox },
  { to: '/admin/mensagens', label: 'Mensagens', icon: MessageSquare },
  { to: '/admin/administradores', label: 'Administradores', icon: Shield, super: true },
  { to: '/admin/permissoes', label: 'Permissões', icon: UserCog, super: true },
  { to: '/admin/auditoria', label: 'Auditoria', icon: History, super: true },
  { to: '/admin/relatorios', label: 'Relatórios', icon: FileText },
  { to: '/admin/perfil', label: 'Perfil', icon: UserCircle },
  { to: '/admin/configuracoes', label: 'Configurações', icon: Settings, super: true },
]

function Logo() {
  return (
    <div className="flex items-center gap-2 px-2 py-2">
      <img src="/logo-unilicungo.jpg" alt="Universidade Licungo" className="h-9 w-9 rounded-full object-cover" />
      <div className="leading-tight">
        <p className="text-sm font-bold">VozUL</p>
        <p className="text-xs text-muted-foreground">Comissão de Ética</p>
      </div>
    </div>
  )
}

function NavItems({ onNavigate }: { onNavigate?: () => void }) {
  const { isSuperAdmin } = useAuth()
  const location = useLocation()
  return (
    <nav className="flex flex-1 flex-col gap-1 px-3">
      {NAV.filter((i) => {
        if (i.super && !isSuperAdmin) return false
        return true
      }).map((item) => {
        const ativo = location.pathname.startsWith(item.to)
        return (
          <NavLink
            key={item.to}
            to={item.to}
            onClick={onNavigate}
            className={cn(
              'relative flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors',
              ativo
                ? 'bg-sky-50 text-sky-700 before:absolute before:inset-y-1 before:left-0 before:w-1 before:rounded-r before:bg-sky-600'
                : 'text-muted-foreground hover:bg-accent hover:text-foreground',
            )}
          >
            <item.icon className="size-4" />
            {item.label}
          </NavLink>
        )
      })}
    </nav>
  )
}

function UserMenu() {
  const { profile, logout, isSuperAdmin } = useAuth()
  const navigate = useNavigate()

  const sair = useCallback(async () => {
    await logout()
    navigate('/login')
  }, [logout, navigate])

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" className="gap-2 px-2">
          <Avatar className="size-8">
            <AvatarFallback className="bg-primary/10 text-primary">
              {siglaNome(profile?.nome_completo)}
            </AvatarFallback>
          </Avatar>
          <div className="hidden text-left leading-tight md:block">
            <p className="max-w-40 truncate text-xs font-semibold">
              {profile?.nome_completo ?? 'Administrador'}
            </p>
            <p className="text-[11px] text-muted-foreground">
              {rotuloRole(profile?.role)}
            </p>
          </div>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-56">
        <DropdownMenuLabel>Minha conta</DropdownMenuLabel>
        {isSuperAdmin && (
          <>
            <DropdownMenuItem onClick={() => navigate('/admin/administradores')}>
              <Shield /> Administradores
            </DropdownMenuItem>
            <DropdownMenuItem onClick={() => navigate('/admin/configuracoes')}>
              <Settings /> Configurações
            </DropdownMenuItem>
            <DropdownMenuSeparator />
          </>
        )}
        <DropdownMenuItem onClick={() => navigate('/admin/perfil')}>
          <UserCircle /> Perfil
        </DropdownMenuItem>
        <DropdownMenuSeparator />
        <DropdownMenuItem variant="destructive" onClick={sair}>
          <LogOut /> Terminar sessão
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}

export function AppLayout() {
  const location = useLocation()

  const titulo =
    NAV.find((i) => location.pathname.startsWith(i.to))?.label ?? 'VozUL'

  return (
    <div className="flex min-h-screen bg-muted/30">
      <aside className="sticky top-0 hidden h-screen w-64 shrink-0 flex-col border-r bg-card md:flex">
        <Logo />
        <Separator />
        <NavItems />
        <div className="p-3">
          <UserMenu />
        </div>
      </aside>

      <div className="flex min-w-0 flex-1 flex-col">
        <header className="sticky top-0 z-30 flex h-14 items-center gap-3 border-b bg-card px-4">
          <Sheet>
            <SheetTrigger asChild>
              <Button variant="ghost" size="icon" className="md:hidden">
                <Menu className="size-5" />
              </Button>
            </SheetTrigger>
            <SheetContent side="left" className="w-64 p-0">
              <Logo />
              <Separator />
              <NavItems />
            </SheetContent>
          </Sheet>
          <h1 className="flex-1 truncate text-base font-bold">{titulo}</h1>
          <NotificationsBell />
          <div className="hidden md:block">
            <UserMenu />
          </div>
        </header>
        <main className="flex-1 p-4 md:p-6">
          <div className="mx-auto max-w-6xl">
            <Outlet />
          </div>
        </main>
      </div>
    </div>
  )
}

