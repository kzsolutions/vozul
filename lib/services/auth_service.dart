import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import 'codigos_guardados_service.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Login com email e senha
  Future<AuthResponse> login(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Login de estudante (número estudante + email + senha)
  Future<AuthResponse> loginEstudante(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Login de admin (email + senha)
  Future<AuthResponse> loginAdmin(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Registo de estudante
  Future<AuthResponse> registarEstudante({
    required String email,
    required String password,
    required String numeroEstudante,
    required String celular,
    String? nomeCompleto,
    String? faculdade,
    String? curso,
  }) async {
    await _verificarDisponibilidade(email, numeroEstudante);

    final result = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'role': 'estudante',
        'nome_completo': nomeCompleto,
        'numero_estudante': numeroEstudante,
        'celular': celular,
        'faculdade': faculdade,
        'curso': curso,
      },
    );

    // Se a confirmação de email estiver desativada, o signUp cria sessão
    // automaticamente. Terminamos a sessão para o estudante fazer login
    // explicitamente antes de entrar no dashboard.
    if (_client.auth.currentSession != null) {
      await _client.auth.signOut();
    }

    // O perfil em 'profiles' é criado automaticamente pelo trigger
    // handle_new_user em auth.users (evita depender de sessão no momento
    // do registo).

    return result;
  }

  /// Pré-verifica se o email e o número de estudante já estão em uso, para
  /// dar um erro claro antes do signUp (que devolveria um 500 genérico).
  Future<void> _verificarDisponibilidade(String email, String numeroEstudante) async {
    try {
      final resp = await _client
          .rpc(
            'verificar_disponibilidade_registo',
            params: {'p_email': email, 'p_numero': numeroEstudante},
          )
          .maybeSingle();

      if (resp == null) return;

      if (resp['numero_disponivel'] == false) {
        throw const AuthException('Este número de estudante já está registado');
      }
      if (resp['email_disponivel'] == false) {
        throw const AuthException('Este email já está registado');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      // se a verificação falhar, avançamos: o signUp ainda valida na base
    }
  }

  /// Obter profile do utilizador atual
  Future<Profile?> getProfile() async {
    if (currentUser == null) return null;

    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', currentUser!.id)
          .single();

      return Profile.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Atualizar profile
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (currentUser == null) return;
    await _client
        .from('profiles')
        .update(updates)
        .eq('id', currentUser!.id);
  }

  /// Alterar senha
  Future<void> alterarSenha(String novaSenha) async {
    await _client.auth.updateUser(UserAttributes(password: novaSenha));
  }

  /// Logout
  ///
  /// Limpa sempre a sessão local, mesmo se o supabase falhar (sessão
  /// expirada, sem rede, etc.), para o utilizador nunca ficar "preso".
  /// Os códigos de denúncia guardados no dispositivo são sempre apagados: caso
  /// contrário a conta seguinte que entrar no aparelho veria as denúncias
  /// anónimas do utilizador anterior.
  Future<void> logout() async {
    try {
      await CodigosGuardadosService().limparTodas();
    } catch (_) {
      // nunca impede o logout
    }

    try {
      await _client.auth.signOut();
    } catch (_) {
      try {
        await _client.auth.signOut(scope: SignOutScope.local);
      } catch (_) {
        // última hipótese: forçar limpeza local
      }
    }
  }

  /// Verificar se é admin ou super admin
  Future<bool> isAdmin() async {
    final profile = await getProfile();
    return profile?.isAdminOuSuper ?? false;
  }

  /// Verificar se é super admin
  Future<bool> isSuperAdmin() async {
    final profile = await getProfile();
    return profile?.isSuperAdmin ?? false;
  }
}