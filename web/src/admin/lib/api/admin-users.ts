import { edgeAdminUsers } from '../../../lib/supabase'
import { supabase } from '../../../lib/supabase'
import type { Role } from '../../../lib/types'

/** Chama a Edge Function admin-users com o JWT da sessão atual. */
async function chamarAdminUsers(body: Record<string, unknown>) {
  const { data } = await supabase.auth.getSession()
  const token = data?.session?.access_token
  if (!token) throw new Error('Sessão expirada. Inicie sessão novamente.')

  const res = await fetch(edgeAdminUsers, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(body),
  })

  const json = (await res.json().catch(() => null)) as
    | { user?: { id: string }; error?: string; message?: string }
    | null

  if (!res.ok) {
    const msg = json?.error ?? json?.message ?? `Erro (HTTP ${res.status})`
    throw new Error(msg)
  }
  return json
}

export interface CriarAdminParams {
  email: string
  password: string
  nomeCompleto: string
  celular?: string
  poloId?: string
  faculdade: string
  role: Role
  numeroEstudante?: string
  curso?: string
}

export async function criarAdmin(
  params: CriarAdminParams,
): Promise<{ id: string }> {
  const json = await chamarAdminUsers({
    action: 'create_user',
    email: params.email,
    password: params.password,
    nome_completo: params.nomeCompleto,
    celular: params.celular,
    polo_id: params.poloId,
    faculdade: params.faculdade,
    role: params.role,
    numero_estudante: params.numeroEstudante,
    curso: params.curso,
  })
  return { id: json?.user?.id ?? '' }
}

export async function eliminarAuthUser(id: string): Promise<void> {
  await chamarAdminUsers({ action: 'delete_user', id })
}