export type Role = 'estudante' | 'admin' | 'super_admin'

export interface Profile {
  id: string
  role: Role
  nome_completo: string | null
  numero_estudante: string | null
  celular: string | null
  email: string | null
  faculdade: string | null
  faculdade_id: string | null
  polo_id: string | null
  curso: string | null
  avatar_url: string | null
  numero_validado_origem: string | null
  numero_validado_estado: string | null
  numero_validado_em: string | null
  created_at: string | null
  updated_at: string | null
}

export type DenunciaStatus =
  | 'Recebida'
  | 'Em análise'
  | 'Investigação'
  | 'Resolvida'
  | 'Encerrada'

export interface Denuncia {
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
  polo_id: string | null
  curso: string | null
  local_ocorrido: string | null
  data_ocorrido: string | null
  status: DenunciaStatus
  anonima: boolean
  estudante_id: string | null
  tem_provas: boolean
  admin_responsavel: string | null
  created_at: string
  updated_at: string
}

export interface Evidencia {
  id: number
  denuncia_id: number
  file_url: string
  file_name: string
  file_type: string
  file_size: number | null
  created_at: string | null
}

export interface Mensagem {
  id: number
  denuncia_id: number
  remetente: 'estudante' | 'comissao'
  conteudo: string
  lida: boolean
  created_at: string
}

export interface Notificacao {
  id: number
  usuario_id: string
  denuncia_id: number | null
  titulo: string
  conteudo: string
  lida: boolean
  created_at: string
}

export interface HistoricoAcesso {
  id: number
  usuario_id: string
  acao: string
  detalhes: string | null
  recurso: string | null
  registro_id: string | null
  ip_address: string | null
  user_agent: string | null
  created_at: string
  profiles?: Pick<Profile, 'nome_completo' | 'email'> | null
}

export interface AdminConfig {
  id: number
  chave: string
  valor: string
  descricao: string | null
  updated_at: string | null
}

export interface Estatisticas {
  total: number
  por_status: Record<DenunciaStatus, number>
  por_categoria: Array<{ categoria: string; count: number }>
  por_faculdade: Array<{ faculdade: string; count: number }>
  por_mes: Array<{ mes: string; label: string; count: number }>
}