import { Navigate, Outlet, useLocation } from 'react-router-dom'
import { useAuth } from '../lib/auth'
import type { ReactNode } from 'react'
import { Loader2, ShieldAlert } from 'lucide-react'
import { Button } from '../components/ui/button'

function TelaCarregamento() {
  return (
    <div className="flex min-h-screen items-center justify-center">
      <Loader2 className="size-8 animate-spin text-primary" />
    </div>
  )
}

export function RequireAuth() {
  const { session, profile, loading } = useAuth()
  const location = useLocation()

  if (loading) return <TelaCarregamento />
  if (!session || !profile) {
    return <Navigate to="/login" state={{ from: location.pathname }} replace />
  }
  if (profile.role !== 'admin' && profile.role !== 'super_admin') { return <Navigate to='/' replace /> }
  return <Outlet />
}

export function RequireSuper({ children }: { children: ReactNode }) {
  const { isSuperAdmin } = useAuth()
  if (!isSuperAdmin) {
    return (
      <div className="flex min-h-[60vh] flex-col items-center justify-center gap-4 p-6 text-center">
        <ShieldAlert className="size-12 text-destructive" />
        <h1 className="text-xl font-bold">Acesso restrito</h1>
        <p className="max-w-md text-sm text-muted-foreground">
          Apenas Super Administradores podem aceder a este conteúdo.
        </p>
      </div>
    )
  }
  return <>{children}</>
}

function PerfilButton() {
  const { logout } = useAuth()
  return (
    <Button variant="outline" onClick={async () => { await logout() }}>
      Terminar sessão
    </Button>
  )
}