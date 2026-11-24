import 'dart:io';
import 'package:flutter/material.dart';
import '../models/denuncia.dart';
import '../models/denuncia_com_mensagem.dart';
import '../services/codigos_guardados_service.dart';
import '../services/denuncia_service.dart';

class DenunciaProvider extends ChangeNotifier {
  final DenunciaService _denunciaService = DenunciaService();
  final CodigosGuardadosService _codigosService = CodigosGuardadosService();

  /// Identificador do utilizador cujos códigos estão carregados em memória.
  /// Evita mostrar códigos de outra conta que tenha usado o mesmo dispositivo.
  String? _codigosDeUsuario;

  List<Denuncia> _minhasDenuncias = [];
  List<DenunciaComMensagem> _conversas = [];
  List<Denuncia> _denunciasAdmin = [];
  Denuncia? _denunciaAtual;
  Map<String, dynamic> _estatisticas = {};
  List<String> _codigosGuardados = [];
  bool _codigosCarregados = false;
  bool _isLoading = false;
  bool _carregandoMinhas = false;
  bool _codigosBloqueados = false;
  String? _error;

  List<Denuncia> get minhasDenuncias => _minhasDenuncias;
  List<DenunciaComMensagem> get conversas => _conversas;
  List<Denuncia> get denunciasAdmin => _denunciasAdmin;
  Denuncia? get denunciaAtual => _denunciaAtual;
  Map<String, dynamic> get estatisticas => _estatisticas;
  List<String> get codigosGuardados => _codigosGuardados;
  bool get isLoading => _isLoading;
  bool get carregandoMinhas => _carregandoMinhas;

  /// Verdadeiro quando o servidor esgotou o orçamento de tentativas de códigos.
  /// Permite à interface avisar o estudante sem revelar se o código existe.
  bool get codigosBloqueados => _codigosBloqueados;
  String? get error => _error;

  /// Total de mensagens da Comissão por ler em todas as conversas
  int get totalNaoLidas =>
      _conversas.fold<int>(0, (soma, c) => soma + c.naoLidas);

  /// Utilizador cujos dados (denúncias e códigos) estão carregados.
  String? get utilizadorAtual => _codigosDeUsuario;

  /// Define o utilizador em contexto. Se mudar de conta, o estado anterior é
  /// descartado para não misturar dados de pessoas diferentes.
  void definirUtilizador(String? userId) {
    if (_codigosDeUsuario == userId) return;
    _codigosDeUsuario = userId;
    _codigosGuardados = [];
    _codigosCarregados = false;
    _minhasDenuncias = [];
    _conversas = [];
    _denunciaAtual = null;
    notifyListeners();
  }

  /// Limpa todo o estado local do estudante (terminar sessão).
  void limparSessao() {
    _codigosDeUsuario = null;
    _codigosGuardados = [];
    _codigosCarregados = false;
    _minhasDenuncias = [];
    _conversas = [];
    _denunciaAtual = null;
    notifyListeners();
  }

  String? get _utilizadorAtual => _codigosDeUsuario;

  /// Criar nova denúncia
  Future<Denuncia?> criarDenuncia({
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final denuncia = await _denunciaService.criarDenuncia(
        categoria: categoria,
        categoriaCustom: categoriaCustom,
        descricao: descricao,
        denunciadoTipo: denunciadoTipo,
        denunciadoNome: denunciadoNome,
        denunciadoNumero: denunciadoNumero,
        denunciadoCelular: denunciadoCelular,
        faculdade: faculdade,
        curso: curso,
        poloId: poloId,
        localOcorrido: localOcorrido,
        dataOcorrido: dataOcorrido,
        anonima: anonima,
        estudanteId: estudanteId,
        emailNotificacao: emailNotificacao,
        evidencias: evidencias,
      );

      _minhasDenuncias.insert(0, denuncia);
      _conversas.insert(
        0,
        DenunciaComMensagem(denuncia: denuncia),
      );
      final userId = _utilizadorAtual;
      if (denuncia.anonima && userId != null) {
        await guardarCodigo(userId, denuncia.codigo);
      }
      _isLoading = false;
      notifyListeners();
      return denuncia;
    } catch (e) {
      _error = 'Erro ao criar denúncia: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Buscar denúncia por código.
  ///
  /// O código só dá acesso às denúncias anónimas (a identificação do autor é
  /// substituída pelo código) ou às próprias denúncias identificadas. O código
  /// é guardado localmente para não se perder, sempre por utilizador.
  Future<void> buscarPorCodigo(String codigo) async {
    _isLoading = true;
    _error = null;
    _codigosBloqueados = false;
    notifyListeners();

    try {
      // O servidor devolve sempre o mesmo resultado para um código inexistente e
      // para um código bloqueado, para não revelar a existência de denúncias.
      // Esta consulta é apenas informativa e não consome tentativa.
      if (!await _denunciaService.haOrcamentoCodigo()) {
        _codigosBloqueados = true;
        _denunciaAtual = null;
        _error =
            'Excedeste o limite de tentativas de códigos nesta hora. '
            'Tenta novamente mais tarde.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final encontrada = await _denunciaService.buscarPorCodigo(codigo);
      _denunciaAtual = encontrada;
      final userId = _utilizadorAtual;

      if (encontrada == null) {
        _error = 'Denúncia não encontrada com o código: $codigo';
      } else if (encontrada.anonima && userId != null) {
        await guardarCodigo(userId, encontrada.codigo);
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao buscar denúncia: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carregar do dispositivo os códigos guardados de denúncias anónimas.
  Future<void> carregarCodigosGuardados(String userId) async {
    definirUtilizador(userId);
    if (_codigosCarregados) return;
    _codigosGuardados = await _codigosService.carregar(userId);
    _codigosCarregados = true;
    notifyListeners();
  }

  Future<void> guardarCodigo(String userId, String codigo) async {
    _codigosGuardados = await _codigosService.guardar(userId, codigo);
    notifyListeners();
  }

  Future<void> removerCodigoGuardado(String userId, String codigo) async {
    _codigosGuardados = await _codigosService.remover(userId, codigo);
    notifyListeners();
  }

  /// Listar as denúncias do estudante (identificadas e anónimas em que
  /// participa) e o resumo de cada conversa com a Comissão.
  Future<void> listarMinhasDenuncias(String userId) async {
    definirUtilizador(userId);
    _carregandoMinhas = true;
    notifyListeners();

    try {
      _conversas = await _denunciaService.listarMinhasDenuncias();
      _minhasDenuncias = _conversas.map((c) => c.denuncia).toList();
      _carregandoMinhas = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao listar denúncias: $e';
      _carregandoMinhas = false;
      notifyListeners();
    }
  }

  /// Actualiza apenas o resumo da conversa de uma denúncia (após abrir o chat).
  void actualizarConversa(int denunciaId, {int naoLidas = 0}) {
    final i = _conversas.indexWhere((c) => c.denuncia.id == denunciaId);
    if (i == -1) return;
    final atual = _conversas[i];
    _conversas[i] = DenunciaComMensagem(
      denuncia: atual.denuncia,
      ultimaMensagem: atual.ultimaMensagem,
      ultimaMensagemData: atual.ultimaMensagemData,
      naoLidas: naoLidas,
    );
    notifyListeners();
  }

  /// Listar denúncias para admin
  Future<void> listarDenunciasAdmin({
    String? faculdade,
    String? categoria,
    String? status,
    String? busca,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _denunciasAdmin = await _denunciaService.listarDenunciasAdmin(
        faculdade: faculdade,
        categoria: categoria,
        status: status,
        busca: busca,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao listar denúncias: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Atualizar status
  Future<void> atualizarStatus(int denunciaId, String novoStatus) async {
    try {
      await _denunciaService.atualizarStatus(denunciaId, novoStatus);

      // Atualizar na lista local
      final index = _denunciasAdmin.indexWhere((d) => d.id == denunciaId);
      if (index != -1) {
        _denunciasAdmin[index] = Denuncia(
          id: _denunciasAdmin[index].id,
          codigo: _denunciasAdmin[index].codigo,
          categoria: _denunciasAdmin[index].categoria,
          descricao: _denunciasAdmin[index].descricao,
          faculdade: _denunciasAdmin[index].faculdade,
          status: novoStatus,
          anonima: _denunciasAdmin[index].anonima,
          createdAt: _denunciasAdmin[index].createdAt,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Erro ao atualizar status: $e';
      notifyListeners();
    }
  }

  /// Carregar estatísticas
  Future<void> carregarEstatisticas({String? faculdade}) async {
    try {
      _estatisticas = await _denunciaService.obterEstatisticas(faculdade: faculdade);
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao carregar estatísticas: $e';
      notifyListeners();
    }
  }

  /// Gerar relatório CSV
  Future<String?> gerarRelatorioCSV({
    String? faculdade,
    String? categoria,
    String? status,
  }) async {
    try {
      return await _denunciaService.gerarRelatorioCSV(
        faculdade: faculdade,
        categoria: categoria,
        status: status,
      );
    } catch (e) {
      _error = 'Erro ao gerar relatório: $e';
      notifyListeners();
      return null;
    }
  }

  void limparErro() {
    _error = null;
    notifyListeners();
  }
}