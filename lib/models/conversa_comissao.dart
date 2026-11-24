import 'denuncia.dart';

/// Conversa da Comissão de Ética com o denunciante, com o resumo da conversa.
///
/// Resultado da RPC `listar_conversas_comissao`. `nao_lidas` conta as
/// mensagens do estudante que ainda não tiveram resposta da Comissão.
class ConversaComissao {
  final Denuncia denuncia;
  final int totalMensagens;
  final int mensagensEstudante;
  final int mensagensComissao;
  final int naoLidas;
  final String? ultimaMensagem;
  final DateTime? ultimaMensagemData;
  final String? ultimaMensagemRemetente;

  const ConversaComissao({
    required this.denuncia,
    this.totalMensagens = 0,
    this.mensagensEstudante = 0,
    this.mensagensComissao = 0,
    this.naoLidas = 0,
    this.ultimaMensagem,
    this.ultimaMensagemData,
    this.ultimaMensagemRemetente,
  });

  bool get temConversa => totalMensagens > 0;

  /// Verdadeiro quando a última palavra foi do estudante (aguarda resposta).
  bool get aguardaResposta =>
      naoLidas > 0 && ultimaMensagemRemetente == 'estudante';

  factory ConversaComissao.fromJson(Map<String, dynamic> json) {
    return ConversaComissao(
      denuncia: Denuncia.fromJson(json),
      totalMensagens: (json['total_mensagens'] as num?)?.toInt() ?? 0,
      mensagensEstudante: (json['mensagens_estudante'] as num?)?.toInt() ?? 0,
      mensagensComissao: (json['mensagens_comissao'] as num?)?.toInt() ?? 0,
      naoLidas: (json['nao_lidas'] as num?)?.toInt() ?? 0,
      ultimaMensagem: json['ultima_mensagem'] as String?,
      ultimaMensagemData: _parseDate(json['ultima_mensagem_data']),
      ultimaMensagemRemetente: json['ultima_mensagem_remetente'] as String?,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}