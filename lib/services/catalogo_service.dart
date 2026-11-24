import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Campus/delegação de uma instituição de ensino.
class Polo {
  final String id;
  final String nome;
  final String cidade;

  /// `true` no campus sede, apresentado por omissão no registo.
  final bool principal;

  const Polo({
    required this.id,
    required this.nome,
    required this.cidade,
    this.principal = false,
  });

  String get rotulo => '$nome — $cidade';
}

/// Faculdade de uma instituição, pertencente a um pólo/delegação.
///
/// A mesma faculdade pode existir em mais do que um pólo, pelo que a lista
/// tem de ser sempre filtrada pelo campus escolhido pelo estudante.
class Faculdade {
  final String id;
  final String nome;
  final String poloId;

  const Faculdade({
    required this.id,
    required this.nome,
    required this.poloId,
  });
}

/// Curso de uma faculdade.
class Curso {
  final String id;
  final String nome;
  final String faculdadeId;

  const Curso({
    required this.id,
    required this.nome,
    required this.faculdadeId,
  });
}

/// Leitura do catálogo com indicação de falha.
///
/// Distingue "não há nada publicado" de "não consegui ler", porque a interface
/// reage de forma diferente: no primeiro caso mostra a lista vazia, no segundo
/// oferece nova tentativa.
class LeituraCatalogo<T> {
  final List<T> itens;
  final String? erro;

  const LeituraCatalogo(this.itens, [this.erro]);

  bool get semDados => itens.isEmpty && erro == null;
  bool get falhou => erro != null;
}

/// Catálogo oficial de faculdades e cursos, por campus/delegação.
///
/// A base de dados é a fonte de verdade: as listas são publicadas pela
/// universidade e o registo do estudante tem de oferecer apenas as faculdades
/// e cursos do campus que ele escolheu. Não existe lista em código para esse
/// efeito — uma lista fixa no cliente seria uma segunda fonte de verdade, que
/// é exactamente o que provocou as listas divergentes.
class CatalogoService {
  // Acesso ao cliente só quando é preciso: construir o serviço não deve
  // exigir que o Supabase já esteja inicializado.
  SupabaseClient get _client => SupabaseConfig.client;

  /// Campus disponíveis, com o sede (principal) em primeiro lugar.
  Future<LeituraCatalogo<Polo>> listarPolos({
    String instituicao = 'licungo',
  }) async {
    try {
      final resposta = await _client
          .from('polos')
          .select('id, nome, cidade, principal')
          .eq('instituicao_id', instituicao)
          .eq('activo', true)
          .order('principal', ascending: false)
          .order('nome');

      return LeituraCatalogo(
        (resposta as List)
            .map((e) => Polo(
                  id: e['id'] as String,
                  nome: e['nome'] as String,
                  cidade: e['cidade'] as String,
                  principal: e['principal'] as bool? ?? false,
                ))
            .toList(),
      );
    } catch (e) {
      return LeituraCatalogo(const [], _mensagem(e));
    }
  }

  /// Faculdades publicadas para o campus indicado.
  Future<LeituraCatalogo<Faculdade>> listarFaculdades(String poloId) async {
    if (poloId.isEmpty) return const LeituraCatalogo([]);

    try {
      final resposta = await _client
          .from('faculdades')
          .select('id, nome, polo_id')
          .eq('polo_id', poloId)
          .eq('activo', true)
          .order('nome');

      return LeituraCatalogo(
        (resposta as List)
            .map((e) => Faculdade(
                  id: e['id'] as String,
                  nome: e['nome'] as String,
                  poloId: e['polo_id'] as String,
                ))
            .toList(),
      );
    } catch (e) {
      return LeituraCatalogo(const [], _mensagem(e));
    }
  }

  /// Cursos publicados para a faculdade indicada.
  Future<LeituraCatalogo<Curso>> listarCursos(String faculdadeId) async {
    if (faculdadeId.isEmpty) return const LeituraCatalogo([]);

    try {
      final resposta = await _client
          .from('cursos')
          .select('id, nome, faculdade_id')
          .eq('faculdade_id', faculdadeId)
          .eq('activo', true)
          .order('nome');

      return LeituraCatalogo(
        (resposta as List)
            .map((e) => Curso(
                  id: e['id'] as String,
                  nome: e['nome'] as String,
                  faculdadeId: e['faculdade_id'] as String,
                ))
            .toList(),
      );
    } catch (e) {
      return LeituraCatalogo(const [], _mensagem(e));
    }
  }

  /// Nomes distintos de faculdades, para filtros que trabalham por nome.
  ///
  /// As denúncias guardam o nome da faculdade (e não o identificador), por isso
  /// o filtro por nome continua a funcionar. Com o catálogo por campus a mesma
  /// faculdade pode existir em dois pólos: daí a remoção de duplicados.
  Future<LeituraCatalogo<String>> listarNomesFaculdades({String? poloId}) async {
    try {
      var consulta = _client
          .from('faculdades')
          .select('nome')
          .eq('activo', true);

      if (poloId != null) consulta = consulta.eq('polo_id', poloId);

      final resposta = await consulta.order('nome');

      final nomes = <String>{};
      for (final e in resposta as List) {
        nomes.add(e['nome'] as String);
      }

      return LeituraCatalogo(nomes.toList());
    } catch (e) {
      return LeituraCatalogo(const [], _mensagem(e));
    }
  }

  /// Locais de ocorrência mapeados para o campus indicado.
  ///
  /// Um campus sem linhas ainda não tem locais definidos (é o caso da
  /// delegação da Beira): o formulário trata a lista vazia como "o estudante
  /// escreve o local", em vez de oferecer opções de outro campus.
  Future<LeituraCatalogo<String>> listarLocais(String poloId) async {
    if (poloId.isEmpty) return const LeituraCatalogo([]);

    try {
      final resposta = await _client
          .from('locais_ocorrencia')
          .select('nome')
          .eq('polo_id', poloId)
          .eq('activo', true)
          .order('ordem')
          .order('nome');

      return LeituraCatalogo(
        (resposta as List).map((e) => e['nome'] as String).toList(),
      );
    } catch (e) {
      return LeituraCatalogo(
        const [],
        _mensagem(e, falha: 'Não foi possível carregar os locais do campus.'),
      );
    }
  }

  String _mensagem(dynamic e, {String? falha}) {
    final msg = e.toString();
    if (msg.contains('Failed host lookup') ||
        msg.contains('SocketException') ||
        msg.contains('Connection reset')) {
      return 'Sem ligação ao servidor. Verifique a internet e tente novamente.';
    }
    return falha ?? 'Não foi possível carregar a lista de faculdades e cursos.';
  }
}