class Mensagem {
  final int id;
  final int denunciaId;
  final String remetente;
  final String conteudo;
  final bool lida;
  final DateTime? createdAt;

  Mensagem({
    required this.id,
    required this.denunciaId,
    required this.remetente,
    required this.conteudo,
    this.lida = false,
    this.createdAt,
  });

  bool get isEstudante => remetente == 'estudante';

  factory Mensagem.fromJson(Map<String, dynamic> json) {
    return Mensagem(
      id: (json['id'] as num).toInt(),
      denunciaId: (json['denuncia_id'] as num).toInt(),
      remetente: json['remetente'] as String,
      conteudo: json['conteudo'] as String,
      lida: json['lida'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'denuncia_id': denunciaId,
      'remetente': remetente,
      'conteudo': conteudo,
    };
  }
}