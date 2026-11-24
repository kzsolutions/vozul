import { createContext, useContext, useEffect, useState, type ReactNode } from 'react'
import { supabase } from '../config/supabase'
import type { Profile } from '../lib/types'

interface AuthContextType {
  user: any
  profile: Profile | null
  loading: boolean
  signIn: (email: string, password: string) => Promise<void>
  signOut: () => Promise<void>
  atualizarProfile: (dados: Record<string, unknown>) => Promise<void>
  recarregarProfile: () => Promise<void>
  isEstudante: boolean
  isAdmin: boolean
  isSuperAdmin: boolean
}

const AuthContext = createContext<AuthContextType>({} as AuthContextType)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<any>(null)
  const [profile, setProfile] = useState<Profile | null>(null)
  const [loading, setLoading] = useState(true)

  async function carregarPerfil(id: string) {
    const { data } = await supabase.from('profiles').select('*').eq('id', id).single()
    setProfile((data as Profile | null) ?? null)
  }

  useEffect(() => {
    supabase.auth.getSession().then((result: any) => {
      const session = result?.data?.session
      setUser(session?.user ?? null)
      if (session?.user) void carregarPerfil(session.user.id)
      setLoading(false)
    })

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event: any, session: any) => {
      setUser(session?.user ?? null)
      if (session?.user) void carregarPerfil(session.user.id)
      else setProfile(null)
    })

    return () => subscription.unsubscribe()
  }, [])

  async function signIn(email: string, password: string) {
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) throw error
  }

  async function signOut() {
    await supabase.auth.signOut({ scope: 'local' }).catch(() => {})
    setProfile(null)
    setUser(null)
  }

  async function atualizarProfile(dados: Record<string, unknown>) {
    if (!user?.id) throw new Error('Sessão não disponível')
    const { error } = await supabase.from('profiles').update(dados).eq('id', user.id)
    if (error) throw error
    await carregarPerfil(user.id)
  }

  async function recarregarProfile() {
    if (user?.id) await carregarPerfil(user.id)
  }

  const isEstudante = profile?.role === 'estudante'
  const isAdmin = profile?.role === 'admin' || profile?.role === 'super_admin'
  const isSuperAdmin = profile?.role === 'super_admin'

  return (
    <AuthContext.Provider value={{ user, profile, loading, signIn, signOut, atualizarProfile, recarregarProfile, isEstudante, isAdmin, isSuperAdmin }}>
      {children}
    </AuthContext.Provider>
  )
}

export const useAuth = () => useContext(AuthContext)
