import { supabase } from '../../../lib/supabase'
import type { Denuncia, DenunciaStatus, Estatisticas, Evidencia } from '../../../lib/types'

export interface FiltrosDenuncias {
  faculdade?: string | null
  categoria?: string | null
  status?: string | null
  busca?: string | null
  offset?: number
  limit?: number
}

const PAGINA = 20

export async function listarDenunciasAdmin(
  filtros: FiltrosDenuncias,
): Promise<{ items: Denuncia[]; total: number; limit: number }> {
  let query = supabase.from('denuncias').select('*', { count: 'exact' })

  if (filtros.faculdade) query = query.eq('faculdade', filtros.faculdade)
  if (filtros.categoria) query = query.eq('categoria', filtros.categoria)
  if (filtros.status) query = query.eq('status', filtros.status)
  if (filtros.busca) {
    const b = `%${filtros.busca.toLowerCase()}%`
    query = query.or(
      `denunciado_nome.ilike.${b},denunciado_numero.ilike.${b},codigo.ilike.${b}`,
    )
  }

  const limit = filtros.limit ?? PAGINA
  const offset = filtros.offset ?? 0
  query = query
    .order('created_at', { ascending: false })
    .range(offset, offset + limit - 1)

  const { data, error, count } = await query
  if (error) throw new Error(`Erro ao listar denúncias: ${error.message}`)
  return { items: (data ?? []) as Denuncia[], total: count ?? 0, limit }
}

export async function obterDenuncia(id: number): Promise<Denuncia> {
  const { data, error } = await supabase
    .from('denuncias')
    .select('*')
    .eq('id', id)
    .single()
  if (error) throw new Error(`Erro ao obter denúncia: ${error.message}`)
  return data as Denuncia
}

export async function atualizarStatusDenuncia(
  id: number,
  status: DenunciaStatus,
): Promise<void> {
  const { error } = await supabase
    .from('denuncias')
    .update({ status, updated_at: new Date().toISOString() })
    .eq('id', id)
  if (error) throw new Error(`Erro ao atualizar status: ${error.message}`)
}

export async function atribuirResponsavel(
  id: number,
  responsavelId: string | null,
): Promise<void> {
  const { error } = await supabase
    .from('denuncias')
    .update({
      admin_responsavel: responsavelId,
      updated_at: new Date().toISOString(),
    })
    .eq('id', id)
  if (error) throw new Error(`Erro ao atribuir responsável: ${error.message}`)
}

export async function listarEvidencias(denunciaId: number): Promise<Evidencia[]> {
  const { data, error } = await supabase
    .from('denuncias_evidencias')
    .select('*')
    .eq('denuncia_id', denunciaId)
    .order('created_at', { ascending: true })
  if (error) throw new Error(`Erro ao listar provas: ${error.message}`)
  return (data ?? []) as Evidencia[]
}

export async function obterUrlAssinada(path: string): Promise<string> {
  const { data, error } = await supabase.storage
    .from('denuncias')
    .createSignedUrl(path, 3600)
  if (error || !data) throw new Error(`Erro ao gerar URL da prova: ${error?.message}`)
  return data.signedUrl
}

export async function listarDenunciasParaEstatisticas(
  faculdade?: string | null,
): Promise<Pick<Denuncia, 'id' | 'categoria' | 'faculdade' | 'status' | 'created_at'>[]> {
  let query = supabase
    .from('denuncias')
    .select('id, categoria, faculdade, status, created_at')
  if (faculdade) query = query.eq('faculdade', faculdade)
  const { data, error } = await query
  if (error) throw new Error(`Erro ao obter estatísticas: ${error.message}`)
  return (data ?? []) as Pick<
    Denuncia,
    'id' | 'categoria' | 'faculdade' | 'status' | 'created_at'
  >[]
}

export interface FiltrosRelatorio {
  de?: string | null
  ate?: string | null
  faculdade?: string | null
  status?: string | null
  categoria?: string | null
}

/** Todas as denúncias (sem paginação) para relatórios/exportação. */
export async function listarDenunciasParaRelatorio(
  filtros: FiltrosRelatorio,
): Promise<Denuncia[]> {
  let query = supabase.from('denuncias').select('*')

  if (filtros.faculdade) query = query.eq('faculdade', filtros.faculdade)
  if (filtros.status) query = query.eq('status', filtros.status)
  if (filtros.categoria) query = query.eq('categoria', filtros.categoria)
  if (filtros.de) query = query.gte('created_at', filtros.de)
  if (filtros.ate) query = query.lte('created_at', filtros.ate)

  query = query.order('created_at', { ascending: false }).limit(2000)

  const { data, error } = await query
  if (error) throw new Error(`Erro ao gerar relatório: ${error.message}`)
  return (data ?? []) as Denuncia[]
}

export function calcularEstatisticas(
  dados: Pick<Denuncia, 'categoria' | 'faculdade' | 'status' | 'created_at'>[],
): Estatisticas {
  const porStatus = {} as Record<DenunciaStatus, number>
  ;(['Recebida', 'Em análise', 'Investigação', 'Resolvida', 'Encerrada']).forEach(
    (s) => (porStatus[s as DenunciaStatus] = 0),
  )

  const porCategoria = new Map<string, number>()
  const porFaculdade = new Map<string, number>()
  const porMes = new Map<string, number>()

  for (const d of dados) {
    porStatus[d.status as DenunciaStatus] += 1
    porCategoria.set(d.categoria, (porCategoria.get(d.categoria) ?? 0) + 1)
    if (d.faculdade)
      porFaculdade.set(d.faculdade, (porFaculdade.get(d.faculdade) ?? 0) + 1)
    const k = d.created_at?.slice(0, 7) ?? ''
    if (k) porMes.set(k, (porMes.get(k) ?? 0) + 1)
  }

  const mes = [...porMes.entries()]
    .map(([mes, count]) => {
      const [ano, m] = mes.split('-')
      return { mes, label: `${m}/${ano.slice(2)}`, count }
    })
    .sort((a, b) => a.mes.localeCompare(b.mes))

  return {
    total: dados.length,
    por_status: porStatus,
    por_categoria: [...porCategoria.entries()]
      .map(([categoria, count]) => ({ categoria, count }))
      .sort((a, b) => b.count - a.count),
    por_faculdade: [...porFaculdade.entries()]
      .map(([faculdade, count]) => ({ faculdade, count }))
      .sort((a, b) => b.count - a.count),
    por_mes: mes,
  }
}