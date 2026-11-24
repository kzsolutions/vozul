import { supabase } from '../../../lib/supabase'
import type { Denuncia, Mensagem } from '../../../lib/types'

export async function listarMensagens(denunciaId: number): Promise<Mensagem[]> {
  const { data, error } = await supabase
    .from('mensagens')
    .select('*')
    .eq('denuncia_id', denunciaId)
    .order('created_at', { ascending: true })
  if (error) throw new Error(`Erro ao carregar mensagens: ${error.message}`)
  return (data ?? []) as Mensagem[]
}

export async function enviarMensagem(
  denunciaId: number,
  conteudo: string,
): Promise<Mensagem> {
  const {
    data: { user },
  } = await supabase.auth.getUser()
  const { data, error } = await supabase
    .from('mensagens')
    .insert({
      denuncia_id: denunciaId,
      remetente: 'comissao',
      conteudo,
      remetente_id: user?.id ?? null,
    })
    .select()
    .single()
  if (error) throw new Error(`Erro ao enviar mensagem: ${error.message}`)
  return data as Mensagem
}

/** Marca como lidas as mensagens do estudante numa denúncia. */
export async function marcarMensagensLidasComissao(denunciaId: number) {
  const { error } = await supabase
    .from('mensagens')
    .update({ lida: true })
    .eq('denuncia_id', denunciaId)
    .eq('remetente', 'estudante')
    .eq('lida', false)
  if (error) throw new Error(`Erro ao marcar mensagens: ${error.message}`)
}

export interface Conversa {
  denuncia: Denuncia
  ultimaMensagem: string | null
  ultimaData: string | null
  naoLidas: number
}

interface LinhaConversa {
  id: number
  codigo: string
  categoria: string
  categoria_custom: string | null
  descricao: string
  denunciado_tipo: string | null
  denunciado_nome: string | null
  denunciado_numero: string | null
  denunciado_celular: string | null
  faculdade: string
  curso: string | null
  local_ocorrido: string | null
  data_ocorrido: string | null
  status: Denuncia['status']
  anonima: boolean
  estudante_id: string | null
  tem_provas: boolean
  admin_responsavel: string | null
  created_at: string
  updated_at: string
  total_mensagens: number
  nao_lidas: number
  ultima_mensagem: string | null
  ultima_mensagem_data: string | null
}

export async function listarConversas(faculdade?: string | null): Promise<Conversa[]> {
  const { data, error } = await supabase.rpc('listar_conversas_comissao', {
    p_faculdade: faculdade ?? null,
  })
  if (error) throw new Error(`Erro ao listar conversas: ${error.message}`)

  return ((data ?? []) as LinhaConversa[])
    .filter((row) => Number(row.total_mensagens) > 0)
    .map((row) => ({
      denuncia: {
        id: row.id,
        codigo: row.codigo,
        categoria: row.categoria,
        categoria_custom: row.categoria_custom,
        descricao: row.descricao,
        denunciado_tipo: row.denunciado_tipo,
        denunciado_nome: row.denunciado_nome,
        denunciado_numero: row.denunciado_numero,
        denunciado_celular: row.denunciado_celular,
        faculdade: row.faculdade,
        polo_id: null,
        curso: row.curso,
        local_ocorrido: row.local_ocorrido,
        data_ocorrido: row.data_ocorrido,
        status: row.status,
        anonima: row.anonima,
        estudante_id: row.estudante_id,
        tem_provas: row.tem_provas,
        admin_responsavel: row.admin_responsavel,
        created_at: row.created_at,
        updated_at: row.updated_at,
      },
      ultimaMensagem: row.ultima_mensagem,
      ultimaData: row.ultima_mensagem_data,
      naoLidas: Number(row.nao_lidas) || 0,
    }))
}

export async function contarNaoLidasComissao(denunciaId: number): Promise<number> {
  const { count, error } = await supabase
    .from('mensagens')
    .select('*', { count: 'exact', head: true })
    .eq('denuncia_id', denunciaId)
    .eq('remetente', 'estudante')
    .eq('lida', false)
  if (error) return 0
  return count ?? 0
}

/** Inscreve-se em novas mensagens de uma denúncia. Devolve função de cancelamento. */
export function subscreverMensagens(
  denunciaId: number,
  onNova: (msg: Mensagem) => void,
): () => void {
  const channel = supabase
    .channel(`mensagens-${denunciaId}`)
    .on(
      'postgres_changes',
      {
        event: 'INSERT',
        schema: 'public',
        table: 'mensagens',
        filter: `denuncia_id=eq.${denunciaId}`,
      },
      (payload) => onNova(payload.new as Mensagem),
    )
    .subscribe()

  return () => {
    supabase.removeChannel(channel)
  }
}