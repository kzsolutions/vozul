import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Resultado da validação do número de estudante contra o registo académico.
class ResultadoValidacao {
  /// `true` válido, `false` recusado, `null` fonte indisponível (pendente).
  final bool? valido;

  /// Mensagem a mostrar ao estudante.
  final String mensagem;

  final String? nome;
  final String? faculdade;
  final String? curso;
  final String? estado;

  /// `live` (fonte oficial da universidade) ou `mock` (simulação).
  final String origem;

  final DateTime? validadoEm;

  const ResultadoValidacao({
    required this.valido,
    required this.mensagem,
    this.nome,
    this.faculdade,
    this.curso,
    this.estado,
    this.origem = 'mock',
    this.validadoEm,
  });

  bool get pendente => valido == null;
  bool get confirmado => valido == true;
}

/// Valida o número de estudante no registo académico da universidade.
///
/// A chamada é feita para a Edge Function `validar-estudante` e nunca
/// directamente para o sistema da universidade: assim a credencial da
/// universidade fica apenas no servidor e nunca chega ao dispositivo.
class ValidacaoService {
  final SupabaseClient _client = SupabaseConfig.client;

  /// Valida um número de estudante.
  ///
  /// Devolve sempre um [ResultadoValidacao]; quando a fonte académica está
  /// indisponível devolve `valido: null` (pendente) em vez de recusar o aluno,
  /// para que uma falha da universidade não impeça o registo de um aluno
  /// legítimo.
  ///
  /// [polo] indica o campus escolhido no registo. Serve para que a
  /// validação fique registada no pólo certo e para que a resposta venha do
  /// catálogo desse campus — a mesma pessoa não é validada com o curso de uma
  /// delegação diferente da que frequentou.
  Future<ResultadoValidacao> validar({
    required String numero,
    String instituicao = 'licungo',
    String? polo,
  }) async {
    try {
      final resposta = await _client.functions.invoke(
        'validar-estudante',
        body: {
          'numero': numero.trim(),
          'instituicao': instituicao,
          if (polo != null) 'polo': polo,
        },
      );

      final corpo = resposta.data is Map
          ? Map<String, dynamic>.from(resposta.data as Map)
          : <String, dynamic>{};

      final valido = corpo['valido'] as bool?;

      return ResultadoValidacao(
        valido: valido,
        mensagem: corpo['mensagem'] as String? ??
            (valido == true
                ? 'Número de estudante validado.'
                : 'Número de estudante não reconhecido.'),
        nome: corpo['nome'] as String?,
        faculdade: corpo['faculdade'] as String?,
        curso: corpo['curso'] as String?,
        estado: corpo['estado'] as String?,
        origem: corpo['origem'] as String? ?? 'mock',
        validadoEm: DateTime.tryParse(corpo['validado_em'] as String? ?? ''),
      );
    } catch (e) {
      final msg = e.toString();

      // A Edge Function responde 503 quando a fonte académica está em baixo.
      final fonteIndisponivel = msg.contains('503') ||
          msg.contains('indisponivel') ||
          msg.contains('Failed host lookup') ||
          msg.contains('Connection reset') ||
          msg.contains('SocketException');

      if (fonteIndisponivel) {
        return const ResultadoValidacao(
          valido: null,
          mensagem: 'O sistema da universidade está temporariamente indisponível. '
              'Verifique a ligação e tente novamente.',
        );
      }

      return ResultadoValidacao(
        valido: false,
        mensagem: 'Não foi possível validar o número de estudante. '
            'Confirme o formato (00.0000.0000) e tente novamente.',
      );
    }
  }

  /// Pede ao servidor que aplique ao perfil a validação oficial já registada.
  ///
  /// Necessário quando a conta foi criada com a fonte académica indisponível:
  /// nesse caso o perfil fica sem validação e o estudante tem de poder
  /// concluir a validação mais tarde.
  ///
  /// [polo] é o campus escolhido. Sem ele a servidor usa a validação válida
  /// mais recente; com ele, só aplica a validação desse campus, para não
  /// deixar no perfil a faculdade de uma delegação que o estudante não
  /// frequenta.
  ///
  /// Devolve `true` se o perfil ficou validado, `false` se ainda não existe
  /// validação válida para o número registado.
  Future<bool> aplicarValidacaoAoPerfil({String? polo}) async {
    try {
      final resposta = await _client.rpc(
        'aplicar_validacao_perfil',
        params: {'p_polo_id': polo},
      );
      return resposta == true;
    } catch (_) {
      return false;
    }
  }
}