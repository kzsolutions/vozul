import { supabase } from '../../../lib/supabase'
import type { Profile, Role } from '../../../lib/types'

export async function listarAdmins(faculdade?: string | null): Promise<Profile[]> {
  let query = supabase
    .from('profiles')
    .select('*')
    .in('role', ['admin', 'super_admin'])
    .order('created_at', { ascending: false })

  if (faculdade) query = query.eq('faculdade', faculdade)

  const { data, error } = await query
  if (error) throw new Error(`Erro ao listar administradores: ${error.message}`)
  return (data ?? []) as Profile[]
}

export async function atualizarNivelAdmin(
  adminId: string,
  novoNivel: Role,
): Promise<void> {
  if (novoNivel === 'admin') {
    const { data, error } = await supabase
      .from('profiles')
      .select('faculdade, polo_id')
      .eq('id', adminId)
      .single()

    if (error) throw new Error(`Erro ao verificar o âmbito: ${error.message}`)
    if (!data?.faculdade || !data?.polo_id) {
      throw new Error(
        'Defina a delegação e a faculdade deste utilizador antes de o tornar Administrador.',
      )
    }
  }

  const { error } = await supabase
    .from('profiles')
    .update({ role: novoNivel })
    .eq('id', adminId)
  if (error) throw new Error(`Erro ao atualizar nível: ${error.message}`)
}

/**
 * Remove a conta de administrador (registo em profiles). O utilizador de
 * autenticação é removido via Edge Function (service role).
 */
export async function removerAdmin(adminId: string): Promise<void> {
  const { error } = await supabase.from('profiles').delete().eq('id', adminId)
  if (error) throw new Error(`Erro ao remover administrador: ${error.message}`)
}