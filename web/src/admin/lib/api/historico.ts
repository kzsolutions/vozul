import { supabase } from '../../../lib/supabase'
import type { HistoricoAcesso } from '../../../lib/types'

export async function listarHistoricoAcessos(
  usuarioId?: string | null,
): Promise<HistoricoAcesso[]> {
  let query = supabase
    .from('historico_acessos')
    .select('*, profiles!historico_acessos_usuario_id_fkey(nome_completo, email)')
    .order('created_at', { ascending: false })
    .limit(100)

  if (usuarioId) query = query.eq('usuario_id', usuarioId)

  const { data, error } = await query
  if (error) throw new Error(`Erro ao carregar histórico: ${error.message}`)
  return (data ?? []) as HistoricoAcesso[]
}

export async function registrarAcesso(opts: {
  usuarioId: string
  acao: string
  detalhes?: string
  recurso?: string
  registroId?: string
}): Promise<void> {
  try {
    await supabase.from('historico_acessos').insert({
      usuario_id: opts.usuarioId,
      acao: opts.acao,
      detalhes: opts.detalhes ?? null,
      recurso: opts.recurso ?? null,
      registro_id: opts.registroId ?? null,
      ip_address: null,
      user_agent: null,
    })
  } catch {
    // registo silencioso (não bloqueia a navegação)
  }
}