import 'denuncia.dart';

/// Uma denúncia do estudante acompanhada do resumo da conversa com a Comissão.
///
/// Resultado da RPC `listar_minhas_denuncias`: nas denúncias anónimas não
/// existe `estudante_id`, pelo que a RLS não devolve a linha ao autor — a RPC
/// junta as duas situações e acrescenta o resumo da conversa.
class DenunciaComMensagem {
  final Denuncia denuncia;
  final String? ultimaMensagem;
  final DateTime? ultimaMensagemData;
  final int naoLidas;

  const DenunciaComMensagem({
    required this.denuncia,
    this.ultimaMensagem,
    this.ultimaMensagemData,
    this.naoLidas = 0,
  });

  bool get temMensagens => ultimaMensagem != null;

  factory DenunciaComMensagem.fromJson(Map<String, dynamic> json) {
    return DenunciaComMensagem(
      denuncia: Denuncia.fromJson(json),
      ultimaMensagem: json['ultima_mensagem'] as String?,
      ultimaMensagemData: _parseDate(json['ultima_mensagem_data']),
      naoLidas: (json['nao_lidas'] as num?)?.toInt() ?? 0,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}