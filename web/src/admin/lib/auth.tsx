import { useAuth as useAppAuth } from '../../contexts/AuthContext'

export function useAuth() {
  const auth = useAppAuth()
  return {
    session: auth.user ? { user: auth.user } : null,
    profile: auth.profile,
    loading: auth.loading,
    isAdmin: auth.isAdmin,
    isSuperAdmin: auth.isSuperAdmin,
    visaoGlobal: auth.isSuperAdmin,
    login: auth.signIn,
    logout: auth.signOut,
    refreshProfile: auth.recarregarProfile,
  }
}

export function AuthProvider({ children }: { children: import('react').ReactNode }) {
  return <>{children}</>
}