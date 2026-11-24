import { supabase } from '../../../lib/supabase'

export interface Polo {
  id: string
  nome: string
  cidade: string
  principal: boolean
}

export interface Faculdade {
  id: string
  nome: string
  polo_id: string
}

export async function listarPolos(): Promise<Polo[]> {
  const { data, error } = await supabase
    .from('polos')
    .select('id, nome, cidade, principal')
    .eq('instituicao_id', 'licungo')
    .eq('activo', true)
    .order('principal', { ascending: false })
    .order('nome')

  if (error) throw new Error(`Erro ao listar delegações: ${error.message}`)
  return (data ?? []) as Polo[]
}

export async function listarFaculdades(poloId: string): Promise<Faculdade[]> {
  if (!poloId) return []

  const { data, error } = await supabase
    .from('faculdades')
    .select('id, nome, polo_id')
    .eq('polo_id', poloId)
    .eq('activo', true)
    .order('nome')

  if (error) throw new Error(`Erro ao listar faculdades: ${error.message}`)
  return (data ?? []) as Faculdade[]
}
