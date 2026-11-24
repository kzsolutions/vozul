import 'dart:async';
import 'package:flutter/material.dart';
import '../models/conversa_comissao.dart';
import '../models/mensagem.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<Mensagem> _mensagens = [];
  StreamSubscription<List<Mensagem>>? _subscription;
  bool _isLoading = false;
  String? _error;

  List<Mensagem> get mensagens => _mensagens;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<ConversaComissao> _conversas = [];
  List<ConversaComissao> get conversas => _conversas;

  /// Lista de conversas da Comissão de Ética
  Future<List<ConversaComissao>> listarConversas({String? faculdade}) async {
    _conversas = await _chatService.listarConversasComissao(faculdade: faculdade);
    return _conversas;
  }

  /// Número de mensagens da Comissão por ler nesta conversa
  int get naoLidas =>
      _mensagens.where((m) => m.remetente == 'comissao' && !m.lida).length;

  void limparErro() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  /// Carregar mensagens
  Future<void> carregarMensagens(int denunciaId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _mensagens = await _chatService.listarMensagens(denunciaId);
      _isLoading = false;
      notifyListeners();

      // Subscrever a novas mensagens
      _subscription?.cancel();
      _subscription = _chatService.subscreverMensagens(denunciaId).listen(
        (mensagens) {
          _mensagens = mensagens;
          notifyListeners();
        },
        onError: (e) {
          _error = 'Não foi possível actualizar a conversa. Verifique a ligação.';
          notifyListeners();
        },
      );
    } catch (e) {
      _error = _traduzirErro(e, aoCarregar: true);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Associar o estudante à conversa da denúncia (caso anónima)
  ///
  /// Tem de terminar ANTES de carregar as mensagens: a RLS só devolve as
  /// mensagens de quem esteja registado em `participantes_denuncia`.
  Future<void> registrarParticipacao(String codigo) async {
    try {
      await _chatService.registrarParticipacao(codigo);
    } catch (e) {
      _error = _traduzirErro(e);
      notifyListeners();
    }
  }

  /// Enviar mensagem. Devolve `true` se a mensagem foi gravada.
  Future<bool> enviarMensagem({
    required int denunciaId,
    required String remetente,
    required String conteudo,
  }) async {
    try {
      await _chatService.enviarMensagem(
        denunciaId: denunciaId,
        remetente: remetente,
        conteudo: conteudo,
      );
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _traduzirErro(e);
      notifyListeners();
      return false;
    }
  }

  String _traduzirErro(dynamic e, {bool aoCarregar = false}) {
    final msg = e.toString();
    if (msg.contains('42501') || msg.contains('row-level security')) {
      return 'Sem permissão para aceder a esta conversa. '
          'Abra a denúncia a partir de «Acompanhar» usando o seu código.';
    }
    if (msg.contains('JWT') ||
        msg.contains('AuthSessionMissing') ||
        msg.contains('401')) {
      return 'Sessão expirada. Entre novamente na sua conta.';
    }
    if (msg.contains('Failed to fetch') ||
        msg.contains('SocketException') ||
        msg.contains('connection')) {
      return 'Sem ligação à internet. Verifique a rede e tente novamente.';
    }
    return aoCarregar
        ? 'Não foi possível carregar a conversa.'
        : 'Não foi possível enviar a mensagem. Tente novamente.';
  }

  /// Marcar como lidas
  Future<void> marcarComoLidas(int denunciaId, String remetente) async {
    try {
      await _chatService.marcarComoLidas(denunciaId, remetente);
    } catch (e) {
      // Ignorar erro silenciosamente
    }
  }

  /// Parar subscription
  void pararSubscription() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    pararSubscription();
    super.dispose();
  }
}