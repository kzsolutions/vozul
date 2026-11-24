import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

class AdminService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Listar administradores
  Future<List<Profile>> listarAdmins({String? faculdade}) async {
    var query = _client
        .from('profiles')
        .select()
        .or('role.in.(admin,super_admin)');

    if (faculdade != null) {
      query = query.eq('faculdade', faculdade);
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List).map((e) => Profile.fromJson(e)).toList();
  }

  /// Criar administrador.
  ///
  /// A conta é criada pela Edge Function `admin-users`, porque criar
  /// utilizadores no Auth exige a service role, que nunca pode estar no cliente.
  Future<Profile?> criarAdmin({
    required String email,
    required String password,
    required String nomeCompleto,
    required String celular,
    String? faculdade,
    String? poloId,
    String role = 'admin',
  }) async {
    try {
      final response = await _client.functions.invoke(
        'admin-users',
        body: {
          'action': 'create_user',
          'email': email,
          'password': password,
          'nome_completo': nomeCompleto,
          'celular': celular,
          'polo_id': poloId,
          'faculdade': faculdade,
          'role': role,
        },
      );

      String? id;
      final dados = response.data;
      if (dados is Map) {
        final utilizador = dados['user'];
        if (utilizador is Map && utilizador['id'] is String) {
          id = utilizador['id'] as String;
        }
      }
      if (id == null) {
        throw Exception('Resposta inválida do servidor');
      }

      final perfil =
          await _client.from('profiles').select().eq('id', id).single();
      return Profile.fromJson(perfil);
    } on FunctionException catch (e) {
      throw Exception(_mensagemFuncao(e));
    }
  }

  /// Remover administrador (conta Auth + perfil).
  Future<void> removerAdmin(String adminId) async {
    try {
      await _client.functions.invoke(
        'admin-users',
        body: {'action': 'delete_user', 'id': adminId},
      );
    } on FunctionException catch (e) {
      throw Exception(_mensagemFuncao(e));
    }
  }

  /// Atualizar nível do administrador.
  ///
  /// Um administrador de nível 2 precisa sempre de delegação e faculdade: sem
  /// elas veria todas as denúncias ou nenhuma.
  Future<void> atualizarNivelAdmin(String adminId, String novoNivel) async {
    if (novoNivel == 'admin') {
      final perfil = await _client
          .from('profiles')
          .select('faculdade, polo_id')
          .eq('id', adminId)
          .single();

      if (perfil['faculdade'] == null || perfil['polo_id'] == null) {
        throw Exception(
          'Defina a delegação e a faculdade deste utilizador antes de o '
          'tornar Administrador.',
        );
      }
    }

    await _client
        .from('profiles')
        .update({'role': novoNivel})
        .eq('id', adminId);
  }

  String _mensagemFuncao(FunctionException erro) {
    final detalhes = erro.details;
    if (detalhes is Map && detalhes['error'] != null) {
      return detalhes['error'].toString();
    }
    return erro.reasonPhrase ?? 'Erro ao contactar o servidor';
  }

  /// Registrar acesso
  Future<void> registrarAcesso({
    required String usuarioId,
    required String acao,
    String? detalhes,
    String? ip,
  }) async {
    await _client.from('historico_acessos').insert({
      'usuario_id': usuarioId,
      'acao': acao,
      'detalhes': detalhes,
      'ip_address': ip,
    });
  }

  /// Listar histórico de acessos
  Future<List<Map<String, dynamic>>> listarHistoricoAcessos({
    String? usuarioId,
    int limit = 100,
  }) async {
    var query = _client
        .from('historico_acessos')
        .select('*, profiles!historico_acessos_usuario_id_fkey(nome_completo, email)');

    if (usuarioId != null) {
      query = query.eq('usuario_id', usuarioId);
    }

    final response = await query
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Listar notificações do admin
  Future<List<Map<String, dynamic>>> listarNotificacoes(String usuarioId) async {
    final response = await _client
        .from('notificacoes')
        .select()
        .eq('usuario_id', usuarioId)
        .order('created_at', ascending: false)
        .limit(50);

    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Marcar notificação como lida
  Future<void> marcarNotificacaoLida(int notificacaoId) async {
    await _client
        .from('notificacoes')
        .update({'lida': true})
        .eq('id', notificacaoId);
  }

  /// Criar notificação
  Future<void> criarNotificacao({
    required String usuarioId,
    int? denunciaId,
    required String titulo,
    required String conteudo,
  }) async {
    await _client.from('notificacoes').insert({
      'usuario_id': usuarioId,
      'denuncia_id': denunciaId,
      'titulo': titulo,
      'conteudo': conteudo,
    });
  }

  /// Buscar denúncia por código
  Future<Map<String, dynamic>?> buscarDenunciaPorCodigo(String codigo) async {
    try {
      final response = await _client
          .from('denuncias')
          .select()
          .eq('codigo', codigo.toUpperCase())
          .single();

      return response;
    } catch (e) {
      return null;
    }
  }
}