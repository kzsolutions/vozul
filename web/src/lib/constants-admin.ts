import type { DenunciaStatus } from './types'

export const APP_NOME = 'VozUL'
export const APP_SUBTITULO = 'Painel da Comissão de Ética'

export const ROLES = ['estudante', 'admin', 'super_admin'] as const

export const STATUS_DENUNCIA: DenunciaStatus[] = [
  'Recebida',
  'Em análise',
  'Investigação',
  'Resolvida',
  'Encerrada',
]

export const CATEGORIAS_DENUNCIA = [
  'Assédio sexual',
  'Corrupção',
  'Venda de notas',
  'Discriminação',
  'Violência verbal',
  'Ameaça',
  'Abuso de poder',
  'Comportamento inadequado',
  'Outro',
]

export const LOCAIS_OCORRENCIA = [
  'Campus Coalane - Bloco I',
  'Campus Coalane - Bloco II',
  'Campus Murropue',
  'Outro',
]

export const TIPOS_DENUNCIADO = ['Docente', 'Estudante', 'Funcionário']

export const FACULDADES_E_CURSOS: Record<string, string[]> = {
  'Faculdade de Engenharia e Planeamento Físico': [
    'Gestão Ambiental e Desenvolvimento Comunitário',
    'Planeamento e Ordenamento Territorial',
    'Informática',
    'Estatística e Gestão de Informação',
  ],
  'Faculdade de Letras e Humanidades': [
    'Direito',
    'Filosofia Social e Política',
    'Sociologia',
  ],
  'Faculdade de Educação': [
    'Ensino de Matemática',
    'AGE - Quelimane, Mocuba e Gurúè',
    'Educação de Infância',
    'Psicologia Educacional',
    'Psicologia Social e das Organizações',
    'Ensino de Português',
    'Ensino de Português - Quelimane, Mocuba e Gurúè',
    'Ensino Básico',
    'Ensino Básico - Quelimane, Mocuba e Gurúè',
    'Ensino de Inglês - Quelimane, Mocuba e Gurúè',
    'Ensino de Geografia',
    'Ensino de Química',
    'Ensino de Física',
    'Ensino de Biologia',
    'Ensino de Biologia - Quelimane, Mocuba e Gurúè',
    'Educação Visual',
    'Actividade Física e Saúde',
    'Gestão do Desporto',
    'Ensino de Ciências Naturais',
    'Ensino de Ciências Sociais',
  ],
  'Faculdade de Economia e Gestão': [
    'Contabilidade',
    'Administração Pública e Autárquica',
    'Gestão dos Recursos Humanos',
    'Gestão de Empresas',
    'Economia e Finanças',
  ],
  'Faculdade de Ciências Agrárias': [
    'Pecuária e Extensão Rural',
    'Agro-processamento',
    'Engenharia Agronómica',
    'Agro-Pecuária',
  ],
  'Faculdade de Medicina': ['Medicina Geral'],
}

export const FACULDADES = Object.keys(FACULDADES_E_CURSOS)

export function cursosDaFaculdade(faculdade: string | null | undefined): string[] {
  if (!faculdade) return []
  return FACULDADES_E_CURSOS[faculdade] ?? []
}

export const MAX_FILES = 5
export const MAX_FILE_SIZE_MB = 25