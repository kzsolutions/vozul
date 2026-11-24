import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/conversa_comissao.dart';
import '../models/mensagem.dart';

class ChatService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Enviar mensagem
  Future<Mensagem> enviarMensagem({
    required int denunciaId,
    required String remetente,
    required String conteudo,
  }) async {
    final response = await _client
        .from('mensagens')
        .insert({
          'denuncia_id': denunciaId,
          'remetente': remetente,
          'conteudo': conteudo,
        })
        .select()
        .single();

    return Mensagem.fromJson(response);
  }

  /// Associar o estudante autenticado a uma denúncia (via código) para poder
  /// ver e responder no chat — essencial nas denúncias anónimas.
  Future<void> registrarParticipacao(String codigo) async {
    await _client.rpc(
      'participar_denuncia',
      params: {'codigo_procurado': codigo},
    );
  }

  /// Listar mensagens de uma denúncia
  Future<List<Mensagem>> listarMensagens(int denunciaId) async {
    final response = await _client
        .from('mensagens')
        .select()
        .eq('denuncia_id', denunciaId)
        .order('created_at', ascending: true);

    return (response as List).map((e) => Mensagem.fromJson(e)).toList();
  }

  /// Subscrever a novas mensagens em tempo real
  Stream<List<Mensagem>> subscreverMensagens(int denunciaId) {
    return _client
        .from('mensagens')
        .stream(primaryKey: ['id'])
        .eq('denuncia_id', denunciaId)
        .order('created_at')
        .map((data) => data.map((e) => Mensagem.fromJson(e)).toList());
  }

  /// Marcar mensagens como lidas
  Future<void> marcarComoLidas(int denunciaId, String remetente) async {
    await _client
        .from('mensagens')
        .update({'lida': true})
        .eq('denuncia_id', denunciaId)
        .neq('remetente', remetente)
        .eq('lida', false);
  }

  /// Contar mensagens não lidas por denúncia
  Future<int> contarNaoLidas(int denunciaId, String remetente) async {
    final response = await _client
        .from('mensagens')
        .select()
        .eq('denuncia_id', denunciaId)
        .neq('remetente', remetente)
        .eq('lida', false);

    return (response as List).length;
  }

  /// Listar conversas da Comissão (com resumo da conversa e mensagens por responder)
  Future<List<ConversaComissao>> listarConversasComissao({
    String? faculdade,
  }) async {
    final response = await _client.rpc(
      'listar_conversas_comissao',
      params: {'p_faculdade': faculdade},
    );

    return (response as List)
        .map((e) => ConversaComissao.fromJson(e))
        .toList();
  }

  /// Listar denúncias com mensagens (para lista de chats do admin)
  Future<List<Map<String, dynamic>>> listarChatsAdmin({
    String? faculdade,
  }) async {
    var query = _client
        .from('denuncias')
        .select('*, mensagens(count)')
        .not('mensagens', 'is', null);

    if (faculdade != null) {
      query = query.eq('faculdade', faculdade);
    }

    final response = await query.order('updated_at', ascending: false);

    return (response as List).cast<Map<String, dynamic>>();
  }
}