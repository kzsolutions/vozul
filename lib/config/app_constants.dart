/// Constantes do VozUL - Universidade Licungo

class AppConstants {
  static const String appNome = 'VozUL';
  static const String appSubtitulo = 'Voz da Universidade Licungo';
  static const String versaoApp = '1.0.0';

  // Limites de upload
  static const int maxFileSizeMB = 25;
  static const int maxFiles = 5;

  // Roles
  static const String roleEstudante = 'estudante';
  static const String roleAdmin = 'admin';
  static const String roleSuperAdmin = 'super_admin';

  // Status de denúncia
  static const List<String> statusDenuncia = [
    'Recebida',
    'Em análise',
    'Investigação',
    'Resolvida',
    'Encerrada',
  ];

  // Categorias de denúncia
  static const List<String> categoriasDenuncia = [
    'Assédio sexual',
    'Corrupção',
    'Venda de notas',
    'Discriminação',
    'Violência verbal',
    'Ameaça',
    'Abuso de poder',
    'Comportamento inadequado',
    'Outro',
  ];

  // Tipos de denunciado
  static const List<String> tiposDenunciado = [
    'Docente',
    'Estudante',
    'Funcionário',
  ];

  // As faculdades, cursos e locais de ocorrência NÃO vivem aqui: são
  // publicados pela universidade na base de dados, por campus/delegacao, e
  // lidos em tempo de execucao pelo CatalogoService. Uma lista fixa no
  // codigo seria uma segunda fonte de verdade, que e o que produziu listas
  // divergentes entre a instituicao e a aplicacao. Um campus sem locais
  // publicados (hoje, a Beira) faz o formulario aceitar texto livre.

  // Tipos de ficheiro aceites
  static const Map<String, List<String>> tiposFicheiro = {
    'Imagens': ['jpg', 'jpeg', 'png'],
    'PDF': ['pdf'],
    'Áudios': ['mp3', 'wav'],
    'Vídeos': ['mp4', 'mov'],
  };
}