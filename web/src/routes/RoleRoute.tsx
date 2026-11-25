import { Navigate, Outlet } from 'react-router-dom'
import { useAuth } from '../contexts/AuthContext'

export default function RoleRoute({ allowed }: { allowed: ('estudante'|'admin'|'super_admin')[] }) {
  const { user, profile, loading } = useAuth()
  if (loading) return <div className='flex h-screen items-center justify-center'>A carregar...</div>
  if (!user) return <Navigate to='/login' replace />
  if (!profile) return <div className='flex h-screen items-center justify-center'>A carregar perfil...</div>
  if (!allowed.includes(profile.role as any)) return <Navigate to='/' replace />
  return <Outlet />
}
