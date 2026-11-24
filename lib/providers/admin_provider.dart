import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../services/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();
  StreamSubscription<List<Map<String, dynamic>>>? _notificacoesSub;
  final SupabaseClient _client = Supabase.instance.client;

  List<Profile> _admins = [];
  List<Map<String, dynamic>> _historicoAcessos = [];
  List<Map<String, dynamic>> _notificacoes = [];
  bool _isLoading = false;
  String? _error;

  List<Profile> get admins => _admins;
  List<Map<String, dynamic>> get historicoAcessos => _historicoAcessos;
  List<Map<String, dynamic>> get notificacoes => _notificacoes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get naoLidas => _notificacoes.where((n) => n['lida'] != true).length;

  /// Listar administradores
  Future<void> listarAdmins({String? faculdade}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _admins = await _adminService.listarAdmins(faculdade: faculdade);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao listar administradores: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Criar administrador
  Future<bool> criarAdmin({
    required String email,
    required String password,
    required String nomeCompleto,
    required String celular,
    String? faculdade,
    String? poloId,
    String role = 'admin',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final admin = await _adminService.criarAdmin(
        email: email,
        password: password,
        nomeCompleto: nomeCompleto,
        celular: celular,
        faculdade: faculdade,
        poloId: poloId,
        role: role,
      );

      if (admin != null) {
        _admins.insert(0, admin);
      }

      _isLoading = false;
      notifyListeners();
      return admin != null;
    } catch (e) {
      _error = 'Erro ao criar administrador: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Remover administrador
  Future<void> removerAdmin(String adminId) async {
    try {
      await _adminService.removerAdmin(adminId);
      _admins.removeWhere((a) => a.id == adminId);
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao remover administrador: $e';
      notifyListeners();
    }
  }

  /// Atualizar nível
  Future<void> atualizarNivelAdmin(String adminId, String novoNivel) async {
    try {
      await _adminService.atualizarNivelAdmin(adminId, novoNivel);
      final index = _admins.indexWhere((a) => a.id == adminId);
      if (index != -1) {
        _admins[index] = _admins[index].copyWith(role: novoNivel);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Erro ao atualizar nível: $e';
      notifyListeners();
    }
  }

  /// Listar histórico de acessos
  Future<void> listarHistoricoAcessos({String? usuarioId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _historicoAcessos = await _adminService.listarHistoricoAcessos(
        usuarioId: usuarioId,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao listar histórico: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Listar notificações
  Future<void> listarNotificacoes(String usuarioId) async {
    try {
      _notificacoes = await _adminService.listarNotificacoes(usuarioId);
      notifyListeners();
    } catch (e) {
      // Ignorar erro silenciosamente
    }
  }

  /// Subscrever a novas notificações em tempo real
  void subscreverNotificacoes(String usuarioId) {
    _notificacoesSub?.cancel();
    _notificacoesSub = _client
        .from('notificacoes')
        .stream(primaryKey: ['id'])
        .eq('usuario_id', usuarioId)
        .order('created_at', ascending: false)
        .listen(
      (data) {
        _notificacoes = data;
        notifyListeners();
      },
      onError: (e) {
        // Ignorar erros de stream (reconexão automática)
      },
    );
  }

  /// Cancelar subscrição de notificações
  void cancelarSubscricaoNotificacoes() {
    _notificacoesSub?.cancel();
    _notificacoesSub = null;
  }

  /// Marcar notificação como lida
  Future<void> marcarNotificacaoLida(int notificacaoId) async {
    try {
      await _adminService.marcarNotificacaoLida(notificacaoId);
      final index = _notificacoes.indexWhere((n) => n['id'] == notificacaoId);
      if (index != -1) {
        _notificacoes[index]['lida'] = true;
        notifyListeners();
      }
    } catch (e) {
      // Ignorar erro silenciosamente
    }
  }

  /// Registrar acesso
  Future<void> registrarAcesso({
    required String usuarioId,
    required String acao,
    String? detalhes,
    String? ip,
  }) async {
    try {
      await _adminService.registrarAcesso(
        usuarioId: usuarioId,
        acao: acao,
        detalhes: detalhes,
        ip: ip,
      );
    } catch (e) {
      // Ignorar erro silenciosamente
    }
  }
}