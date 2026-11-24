class Denuncia {
  final int id;
  final String codigo;
  final String categoria;
  final String? categoriaCustom;
  final String descricao;
  final String? denunciadoTipo;
  final String? denunciadoNome;
  final String? denunciadoNumero;
  final String? denunciadoCelular;
  final String faculdade;
  final String? curso;
  final String? localOcorrido;
  final DateTime? dataOcorrido;
  final String status;
  final bool anonima;
  final String? estudanteId;
  final String? emailNotificacao;
  final bool temProvas;
  final String? adminResponsavel;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Denuncia({
    required this.id,
    required this.codigo,
    required this.categoria,
    this.categoriaCustom,
    required this.descricao,
    this.denunciadoTipo,
    this.denunciadoNome,
    this.denunciadoNumero,
    this.denunciadoCelular,
    required this.faculdade,
    this.curso,
    this.localOcorrido,
    this.dataOcorrido,
    this.status = 'Recebida',
    this.anonima = true,
    this.estudanteId,
    this.emailNotificacao,
    this.temProvas = false,
    this.adminResponsavel,
    this.createdAt,
    this.updatedAt,
  });

  String get displayCategoria =>
      categoria == 'Outro' && categoriaCustom != null
          ? categoriaCustom!
          : categoria;

  factory Denuncia.fromJson(Map<String, dynamic> json) {
    return Denuncia(
      id: (json['id'] as num).toInt(),
      codigo: json['codigo'] as String,
      categoria: json['categoria'] as String,
      categoriaCustom: json['categoria_custom'] as String?,
      descricao: json['descricao'] as String,
      denunciadoTipo: json['denunciado_tipo'] as String?,
      denunciadoNome: json['denunciado_nome'] as String?,
      denunciadoNumero: json['denunciado_numero'] as String?,
      denunciadoCelular: json['denunciado_celular'] as String?,
      faculdade: json['faculdade'] as String,
      curso: json['curso'] as String?,
      localOcorrido: json['local_ocorrido'] as String?,
      dataOcorrido: _parseDate(json['data_ocorrido']),
      status: json['status'] as String? ?? 'Recebida',
      anonima: json['anonima'] as bool? ?? true,
      estudanteId: json['estudante_id'] as String?,
      emailNotificacao: json['email_notificacao'] as String?,
      temProvas: json['tem_provas'] as bool? ?? false,
      adminResponsavel: json['admin_responsavel'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  Map<String, dynamic> toJson() {
    return {
      'categoria': categoria,
      'categoria_custom': categoriaCustom,
      'descricao': descricao,
      'denunciado_tipo': denunciadoTipo,
      'denunciado_nome': denunciadoNome,
      'denunciado_numero': denunciadoNumero,
      'denunciado_celular': denunciadoCelular,
      'faculdade': faculdade,
      'curso': curso,
      'local_ocorrido': localOcorrido,
      'data_ocorrido': dataOcorrido?.toIso8601String(),
      'status': status,
      'anonima': anonima,
      'estudante_id': estudanteId,
      'tem_provas': temProvas,
    };
  }
}