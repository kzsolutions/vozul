import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL ?? ''
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY ?? ''

function usarProxyFunctions(): boolean {
  return typeof window !== 'undefined' && ['localhost', '127.0.0.1'].includes(window.location.hostname)
}

const fetchComProxy: typeof fetch = (input, init) => {
  const url = typeof input === 'string' ? input : input instanceof URL ? input.href : input.url
  if (!usarProxyFunctions() || !url.includes('/functions/v1/')) return fetch(input, init)
  const destino = new URL(url)
  const relativo = `${destino.pathname}${destino.search}`
  if (input instanceof Request) return fetch(new Request(relativo, input), init)
  return fetch(relativo, init)
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
  },
  global: { fetch: fetchComProxy },
})

export const EDGE_FUNCTIONS_URL = usarProxyFunctions() ? '/functions/v1' : `${supabaseUrl}/functions/v1`
export const edgeAdminUsers = `${EDGE_FUNCTIONS_URL}/admin-users`
