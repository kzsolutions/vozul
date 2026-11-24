import { supabase } from '../../../lib/supabase'

export type PermissaoRole = 'admin' | 'super_admin'

export interface Permissao {
  chave: string
  rotulo: string
  descricao: string | null
  modulo: string
  ativo: boolean
}

export interface PermissaoPerfil {
  role: PermissaoRole
  permissao_chave: string
  permitido: boolean
}

export interface PermissaoAdmin {
  usuario_id: string
  permissao_chave: string
  permitido: boolean
  updated_by: string | null
  updated_at: string | null
}

export async function listarPermissoes(): Promise<Permissao[]> {
  const { data, error } = await supabase
    .from('permissoes')
    .select('chave, rotulo, descricao, modulo, ativo')
    .eq('ativo', true)
    .order('modulo')
    .order('rotulo')

  if (error) throw new Error(`Erro ao listar permissões: ${error.message}`)
  return (data ?? []) as Permissao[]
}

export async function listarPermissoesPerfil(): Promise<PermissaoPerfil[]> {
  const { data, error } = await supabase
    .from('perfil_permissoes')
    .select('role, permissao_chave, permitido')

  if (error) throw new Error(`Erro ao listar permissões por perfil: ${error.message}`)
  return (data ?? []) as PermissaoPerfil[]
}

export async function listarPermissoesAdmin(): Promise<PermissaoAdmin[]> {
  const { data, error } = await supabase
    .from('admin_permissoes')
    .select('usuario_id, permissao_chave, permitido, updated_by, updated_at')

  if (error) throw new Error(`Erro ao listar ajustes por administrador: ${error.message}`)
  return (data ?? []) as PermissaoAdmin[]
}

export async function salvarPermissaoPerfil(
  role: PermissaoRole,
  permissao_chave: string,
  permitido: boolean,
): Promise<void> {
  const { error } = await supabase.from('perfil_permissoes').upsert({
    role,
    permissao_chave,
    permitido,
    updated_at: new Date().toISOString(),
  })
  if (error) throw new Error(`Erro ao guardar permissão do perfil: ${error.message}`)
}

export async function salvarPermissaoAdmin(
  usuario_id: string,
  permissao_chave: string,
  permitido: boolean,
): Promise<void> {
  const { error } = await supabase.from('admin_permissoes').upsert({
    usuario_id,
    permissao_chave,
    permitido,
    updated_at: new Date().toISOString(),
  })
  if (error) throw new Error(`Erro ao guardar permissão do administrador: ${error.message}`)
}

export async function removerPermissoesAdmin(usuario_id: string): Promise<void> {
  const { error } = await supabase
    .from('admin_permissoes')
    .delete()
    .eq('usuario_id', usuario_id)
  if (error) throw new Error(`Erro ao remover ajustes: ${error.message}`)
}
