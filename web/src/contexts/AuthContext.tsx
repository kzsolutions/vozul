import { createContext, useContext, useEffect, useRef, useState, type ReactNode } from 'react'
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
  const profileIdRef = useRef<string | null>(null)

  async function carregarPerfil(id: string) {
    const { data } = await supabase.from('profiles').select('*').eq('id', id).single()
    const next = (data as Profile | null) ?? null
    profileIdRef.current = next?.id ?? id
    setProfile(next)
    return next
  }

  useEffect(() => {
    let active = true

    async function syncSession(session: any) {
      const nextUser = session?.user ?? null
      if (!active) return
      setUser(nextUser)
      if (nextUser?.id) {
        if (profileIdRef.current !== nextUser.id) setProfile(null)
        await carregarPerfil(nextUser.id)
      } else {
        profileIdRef.current = null
        setProfile(null)
      }
      if (active) setLoading(false)
    }

    supabase.auth.getSession().then(({ data }) => {
      void syncSession(data.session)
    }).catch(() => {
      if (active) setLoading(false)
    })

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setLoading(true)
      void syncSession(session)
    })

    return () => {
      active = false
      subscription.unsubscribe()
    }
  }, [])

  async function signIn(email: string, password: string) {
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) throw error
  }

  async function signOut() {
    await supabase.auth.signOut({ scope: 'local' }).catch(() => {})
    profileIdRef.current = null
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
