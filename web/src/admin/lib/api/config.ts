import { supabase } from '../../../lib/supabase'
import type { AdminConfig } from '../../../lib/types'

export async function listarConfiguracoes(): Promise<AdminConfig[]> {
  const { data, error } = await supabase
    .from('admin_config')
    .select('*')
    .order('chave', { ascending: true })
  if (error) throw new Error(`Erro ao carregar configurações: ${error.message}`)
  return (data ?? []) as AdminConfig[]
}

export async function atualizarConfiguracao(id: number, valor: string): Promise<void> {
  const { error } = await supabase
    .from('admin_config')
    .update({ valor, updated_at: new Date().toISOString() })
    .eq('id', id)
  if (error) throw new Error(`Erro ao atualizar configuração: ${error.message}`)
}