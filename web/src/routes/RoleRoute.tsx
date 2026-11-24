import { Navigate, Outlet } from 'react-router-dom'
import { useAuth } from '../contexts/AuthContext'

export default function RoleRoute({ allowed }: { allowed: ('estudante'|'admin'|'super_admin')[] }) {
  const { profile, loading } = useAuth()
  if (loading) return <div className='flex h-screen items-center justify-center'>A carregar...</div>
  if (!profile || !allowed.includes(profile.role as any)) return <Navigate to='/login' replace />
  return <Outlet />
}
