class Notificacao {
  final int id;
  final String usuarioId;
  final int? denunciaId;
  final String titulo;
  final String conteudo;
  final bool lida;
  final DateTime? createdAt;

  Notificacao({
    required this.id,
    required this.usuarioId,
    this.denunciaId,
    required this.titulo,
    required this.conteudo,
    this.lida = false,
    this.createdAt,
  });

  factory Notificacao.fromJson(Map<String, dynamic> json) {
    return Notificacao(
      id: (json['id'] as num).toInt(),
      usuarioId: json['usuario_id'] as String,
      denunciaId: json['denuncia_id'] != null
          ? (json['denuncia_id'] as num).toInt()
          : null,
      titulo: json['titulo'] as String,
      conteudo: json['conteudo'] as String,
      lida: json['lida'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}