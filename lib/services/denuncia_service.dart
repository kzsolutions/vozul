import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/denuncia.dart';
import '../models/denuncia_com_mensagem.dart';

class DenunciaService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Criar nova denúncia
  Future<Denuncia> criarDenuncia({
    required String categoria,
    String? categoriaCustom,
    required String descricao,
    String? denunciadoTipo,
    String? denunciadoNome,
    String? denunciadoNumero,
    String? denunciadoCelular,
    required String faculdade,
    String? curso,
    String? poloId,
    String? localOcorrido,
    DateTime? dataOcorrido,
    required bool anonima,
    String? estudanteId,
    String? emailNotificacao,
    List<File>? evidencias,
  }) async {
    // Criar denúncia
    final denunciaData = {
      'categoria': categoria,
      'categoria_custom': categoriaCustom,
      'descricao': descricao,
      'denunciado_tipo': _normalizarDenunciadoTipo(denunciadoTipo),
      'denunciado_nome': denunciadoNome,
      'denunciado_numero': denunciadoNumero,
      'denunciado_celular': denunciadoCelular,
      'faculdade': faculdade,
      'curso': curso,
      // Campus da denuncia. Quando enviado, a base de dados exige que
      // faculdade/curso pertencam a esse campus.
      'p_polo_id': poloId,
      'local_ocorrido': localOcorrido,
      'data_ocorrido': dataOcorrido == null
          ? null
          : dataOcorrido.toIso8601String().split('T').first,
      'anonima': anonima,
      'estudante_id': estudanteId,
      'tem_provas': evidencias != null && evidencias.isNotEmpty,
    };

    if (emailNotificacao != null && emailNotificacao.trim().isNotEmpty) {
      denunciaData['email_notificacao'] = emailNotificacao.trim();
    }

    // RPC SECURITY DEFINER: devolve a linha criada mesmo em denúncias
    // anónimas (o INSERT ... RETURNING direto falha com 42501 nesses casos).
    final response = await _client
        .rpc('criar_denuncia', params: denunciaData)
        .single();

    final denuncia = Denuncia.fromJson(response);

    // Upload de evidências
    if (evidencias != null && evidencias.isNotEmpty) {
      await _uploadEvidencias(denuncia.id, evidencias);
    }

    return denuncia;
  }

  /// Normaliza o tipo do denunciado para o formato aceite pelo check
  /// constraint da base de dados (ex: "Funcionário" -> "funcionario").
  String? _normalizarDenunciadoTipo(String? tipo) {
    if (tipo == null) return null;
    final t = tipo.toLowerCase().trim();
    if (t == 'funcionário') return 'funcionario';
    return t;
  }

  /// Upload de evidências
  Future<void> _uploadEvidencias(int denunciaId, List<File> files) async {
    for (final file in files) {
      final fileName =
          '${denunciaId}_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final filePath = 'evidencias/$fileName';

      await _client.storage.from('denuncias').upload(filePath, file);

      // Armazenar o caminho no bucket privado (URLs públicas não são usadas)
      await _client.from('denuncias_evidencias').insert({
        'denuncia_id': denunciaId,
        'file_url': filePath,
        'file_name': file.path.split('/').last,
        'file_type': file.path.split('.').last,
        'file_size': await file.length(),
      });
    }
  }

  /// Obter URL assinada (temporária) de uma evidência
  Future<String> obterUrlEvidencia(String storagePath) async {
    final signedUrl = await _client.storage
        .from('denuncias')
        .createSignedUrl(storagePath, 3600); // 1 hora
    return signedUrl.toString();
  }

  /// Listar evidências de uma denúncia
  Future<List<Map<String, dynamic>>> listarEvidencias(int denunciaId) async {
    final response = await _client
        .from('denuncias_evidencias')
        .select()
        .eq('denuncia_id', denunciaId);

    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Verificar se ainda existe orçamento de tentativas para códigos.
  ///
  /// A RPC `orcamento_codigo_disponivel` é STABLE e não consome tentativa: só
  /// informa a aplicação de que o limite por conta e por hora (ou o limite de
  /// falhas consecutivas) foi esgotado. Serve para avisar o estudante antes de
  /// gastar uma tentativa com um código que não vai ser pesquisado.
  ///
  /// Em caso de erro assume-se que há orçamento: o limite é aplicado pelo
  /// servidor de qualquer forma, e falhar aqui não deve impedir a utilização.
  Future<bool> haOrcamentoCodigo() async {
    try {
      final response = await _client.rpc('orcamento_codigo_disponivel');
      return response != false;
    } catch (_) {
      return true;
    }
  }

  /// Buscar denúncia por código
  ///
  /// Usa a RPC `buscar_denuncia_por_codigo` (SECURITY DEFINER) porque as
  /// denúncias anónimas têm `estudante_id = null` e ficam invisíveis à RLS
  /// normal — o código funciona como credencial de acompanhamento.
  Future<Denuncia?> buscarPorCodigo(String codigo) async {
    try {
      final response = await _client
          .rpc('buscar_denuncia_por_codigo', params: {'codigo_procurado': codigo})
          .single();

      return Denuncia.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Listar denúncias do estudante (identificadas + anónimas em que participa)
  ///
  /// Usa a RPC `listar_minhas_denuncias` porque as denúncias anónimas têm
  /// `estudante_id = NULL` e, por isso, não aparecem na consulta directa
  /// (a RLS só devolve ao autor). A RPC junta as duas situações e traz já a
  /// última mensagem e o número de mensagens por ler.
  Future<List<DenunciaComMensagem>> listarMinhasDenuncias() async {
    final response = await _client.rpc('listar_minhas_denuncias');

    return (response as List)
        .map((e) => DenunciaComMensagem.fromJson(e))
        .toList();
  }

  /// Total de mensagens da Comissão por ler em todas as conversas
  Future<int> contarNaoLidasTotal() async {
    final lista = await listarMinhasDenuncias();
    return lista.fold<int>(0, (soma, d) => soma + d.naoLidas);
  }

  /// Listar denúncias para admin (por faculdade)
  Future<List<Denuncia>> listarDenunciasAdmin({
    String? faculdade,
    String? categoria,
    String? status,
    String? busca,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _client.from('denuncias').select();

    if (faculdade != null) {
      query = query.eq('faculdade', faculdade);
    }

    if (categoria != null) {
      query = query.eq('categoria', categoria);
    }

    if (status != null) {
      query = query.eq('status', status);
    }

    if (busca != null && busca.isNotEmpty) {
      query = query.or('denunciado_nome.ilike.%$busca%,denunciado_numero.ilike.%$busca%,codigo.ilike.%$busca%');
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List).map((e) => Denuncia.fromJson(e)).toList();
  }

  /// Atualizar status da denúncia
  Future<void> atualizarStatus(int denunciaId, String novoStatus) async {
    await _client
        .from('denuncias')
        .update({'status': novoStatus})
        .eq('id', denunciaId);
  }

  /// Obter estatísticas
  Future<Map<String, dynamic>> obterEstatisticas({String? faculdade}) async {
    var query = _client.from('denuncias').select('categoria, faculdade, status, created_at');

    if (faculdade != null) {
      query = query.eq('faculdade', faculdade);
    }

    final response = await query;

    final List<Map<String, dynamic>> data = (response as List).cast<Map<String, dynamic>>();

    // Total
    final total = data.length;

    // Por status
    final porStatus = <String, int>{};
    for (final item in data) {
      final status = item['status'] as String;
      porStatus[status] = (porStatus[status] ?? 0) + 1;
    }

    // Por categoria
    final porCategoria = <String, int>{};
    for (final item in data) {
      final cat = item['categoria'] as String;
      porCategoria[cat] = (porCategoria[cat] ?? 0) + 1;
    }

    // Por faculdade
    final porFaculdade = <String, int>{};
    for (final item in data) {
      final fac = item['faculdade'] as String;
      porFaculdade[fac] = (porFaculdade[fac] ?? 0) + 1;
    }

    // Evolução mensal
    final porMes = <String, int>{};
    for (final item in data) {
      final createdAt = DateTime.tryParse(item['created_at'] as String? ?? '');
      if (createdAt != null) {
        final chave = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}';
        porMes[chave] = (porMes[chave] ?? 0) + 1;
      }
    }

    return {
      'total': total,
      'por_status': porStatus,
      'por_categoria': porCategoria,
      'por_faculdade': porFaculdade,
      'por_mes': porMes,
    };
  }

  /// Gerar relatório CSV
  Future<String> gerarRelatorioCSV({
    String? faculdade,
    String? categoria,
    String? status,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    var query = _client.from('denuncias').select();

    if (faculdade != null) query = query.eq('faculdade', faculdade);
    if (categoria != null) query = query.eq('categoria', categoria);
    if (status != null) query = query.eq('status', status);

    final response = await query.order('created_at', ascending: false);
    final denuncias = (response as List).map((e) => Denuncia.fromJson(e)).toList();

    final buffer = StringBuffer();
    buffer.writeln('Código,Categoria,Faculdade,Status,Data,Anónima');

    for (final d in denuncias) {
      buffer.writeln(
        '"${d.codigo}","${d.displayCategoria}","${d.faculdade}","${d.status}","${d.createdAt}","${d.anonima}"',
      );
    }

    return buffer.toString();
  }
}