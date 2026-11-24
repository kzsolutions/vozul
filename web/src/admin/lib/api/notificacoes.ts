import { supabase } from '../../../lib/supabase'
import type { Notificacao } from '../../../lib/types'

export async function listarNotificacoes(usuarioId: string): Promise<Notificacao[]> {
  const { data, error } = await supabase
    .from('notificacoes')
    .select('*')
    .eq('usuario_id', usuarioId)
    .order('created_at', { ascending: false })
    .limit(50)
  if (error) throw new Error(`Erro ao carregar notificações: ${error.message}`)
  return (data ?? []) as Notificacao[]
}

export async function marcarNotificacaoLida(id: number): Promise<void> {
  const { error } = await supabase
    .from('notificacoes')
    .update({ lida: true })
    .eq('id', id)
  if (error) throw new Error(`Erro ao marcar notificação: ${error.message}`)
}

export async function marcarTodasLidas(usuarioId: string): Promise<void> {
  const { error } = await supabase
    .from('notificacoes')
    .update({ lida: true })
    .eq('usuario_id', usuarioId)
    .eq('lida', false)
  if (error) throw new Error(`Erro ao marcar notificações: ${error.message}`)
}

/** Notifica um estudante (ex.: quando o estado da denúncia muda). */
export async function notificarEstudante(opts: {
  usuarioId: string
  titulo: string
  conteudo: string
  denunciaId?: number | null
}): Promise<void> {
  try {
    await supabase.from('notificacoes').insert({
      usuario_id: opts.usuarioId,
      titulo: opts.titulo,
      conteudo: opts.conteudo,
      denuncia_id: opts.denunciaId ?? null,
      lida: false,
    })
  } catch {
    // não crítico
  }
}

/** Inscreve-se em novas notificações do utilizador. Devolve função de cancelamento. */
export function subscreverNotificacoes(
  usuarioId: string,
  onNova: (notif: Notificacao) => void,
): () => void {
  const channel = supabase
    .channel(`notificacoes-${usuarioId}`)
    .on(
      'postgres_changes',
      {
        event: 'INSERT',
        schema: 'public',
        table: 'notificacoes',
        filter: `usuario_id=eq.${usuarioId}`,
      },
      (payload) => onNova(payload.new as Notificacao),
    )
    .subscribe()

  return () => {
    supabase.removeChannel(channel)
  }
}