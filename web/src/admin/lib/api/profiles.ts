import { supabase } from '../../../lib/supabase'
import type { Profile } from '../../../lib/types'

export async function obterPerfil(id: string): Promise<Profile | null> {
  const { data, error } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', id)
    .maybeSingle()
  if (error) return null
  return (data as Profile) ?? null
}

export async function atualizarPerfil(
  id: string,
  campos: Partial<Pick<Profile, 'nome_completo' | 'celular'>>,
): Promise<void> {
  const { error } = await supabase
    .from('profiles')
    .update({ ...campos, updated_at: new Date().toISOString() })
    .eq('id', id)
  if (error) throw new Error(`Erro ao atualizar perfil: ${error.message}`)
}