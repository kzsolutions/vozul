import 'package:flutter/material.dart';
import '../models/profile.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  Profile? _profile;
  bool _isLoading = false;
  String? _error;

  Profile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _authService.currentUser != null;
  bool get isEstudante => _profile?.isEstudante ?? false;
  bool get isAdmin => _profile?.isAdminOuSuper ?? false;
  bool get isSuperAdmin => _profile?.isSuperAdmin ?? false;

  /// Verificar sessão existente
  Future<void> verificarSessao() async {
    _isLoading = true;
    notifyListeners();

    if (_authService.currentUser != null) {
      _profile = await _authService.getProfile();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.login(email, password);
      _profile = await _authService.getProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _tratarErro(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Registo de estudante
  Future<bool> registarEstudante({
    required String email,
    required String password,
    required String numeroEstudante,
    required String celular,
    String? nomeCompleto,
    String? faculdade,
    String? curso,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.registarEstudante(
        email: email,
        password: password,
        numeroEstudante: numeroEstudante,
        celular: celular,
        nomeCompleto: nomeCompleto,
        faculdade: faculdade,
        curso: curso,
      );
      _profile = await _authService.getProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _tratarErro(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Atualizar profile
  Future<void> atualizarProfile(Map<String, dynamic> updates) async {
    try {
      await _authService.updateProfile(updates);
      _profile = await _authService.getProfile();
      notifyListeners();
    } catch (e) {
      _error = _tratarErro(e);
      notifyListeners();
    }
  }

  /// Recarregar o perfil a partir do servidor.
  ///
  /// Necessário depois de uma acção do servidor alterar dados que o cliente não
  /// pode escrever (por exemplo, a validação académica).
  Future<void> recarregarProfile() async {
    try {
      _profile = await _authService.getProfile();
      notifyListeners();
    } catch (_) {
      // mantém o perfil atual: falhar a leitura não deve limpar o ecrã
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (_) {
      // nunca falha: limpa o estado local na mesma
    }
    _profile = null;
    notifyListeners();
  }

  String _tratarErro(dynamic e) {
    final msg = e.toString();
    if (msg.contains('Este número de estudante já está registado')) {
      return 'Este número de estudante já está registado';
    }
    if (msg.contains('Este email já está registado')) {
      return 'Este email já está registado';
    }
    if (msg.contains('Invalid login credentials')) {
      return 'Email ou senha incorretos';
    }
    if (msg.contains('User already registered')) {
      return 'Este email já está registado';
    }
    if (msg.contains('Database error saving new user') ||
        msg.contains('unexpected_failure')) {
      return 'Não foi possível criar a conta. Confirme que o email e o número '
          'de estudante (formato 00.0000.0000) ainda não estão registados e '
          'tente novamente.';
    }
    if (msg.contains('over_email.send_rate_limit') ||
        msg.contains('429')) {
      return 'Muitos pedidos seguidos. Aguarde uns segundos e tente novamente.';
    }
    if (msg.contains('Password should be at least')) {
      return 'A senha deve ter pelo menos 6 caracteres';
    }
    if (msg.contains('23505') ||
        msg.contains('duplicate key') ||
        msg.contains('numero_estudante')) {
      return 'Este número de estudante já está registado';
    }
    return 'Erro: ${e.toString()}';
  }
}