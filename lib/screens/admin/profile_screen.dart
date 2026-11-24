import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/formatters.dart';

class ProfileScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  final VoidCallback? onLogout;

  const ProfileScreen({super.key, this.onNavigateTab, this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  final _nomeController = TextEditingController();
  final _celularController = TextEditingController();
  final _emailController = TextEditingController();

  // Senha
  final _senhaAtualController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = context.read<AuthProvider>().profile;
      if (profile != null) {
        _nomeController.text = profile.nomeCompleto ?? '';
        _celularController.text = profile.celular ?? '';
        _emailController.text = profile.email ?? '';
      }
    });
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _celularController.dispose();
    _emailController.dispose();
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _salvarDados() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.atualizarProfile({
      'nome_completo': _nomeController.text.trim(),
      'celular': _celularController.text.trim(),
    });

    if (mounted) {
      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados atualizados com sucesso')),
      );
    }
  }

  Future<void> _alterarSenha() async {
    if (_novaSenhaController.text.isEmpty) {
      _mostrarErro('Digite a nova senha');
      return;
    }
    if (_novaSenhaController.text.length < 6) {
      _mostrarErro('A senha deve ter pelo menos 6 caracteres');
      return;
    }
    if (_novaSenhaController.text != _confirmarSenhaController.text) {
      _mostrarErro('As senhas não coincidem');
      return;
    }

    try {
      final authService = AuthService();
      await authService.alterarSenha(_novaSenhaController.text);
      if (mounted) {
        _senhaAtualController.clear();
        _novaSenhaController.clear();
        _confirmarSenhaController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Senha alterada com sucesso')),
        );
      }
    } catch (e) {
      _mostrarErro('Erro ao alterar senha: $e');
    }
  }

  void _mostrarErro(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.vermelho),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profile = authProvider.profile;
    final isSuperAdmin = profile?.isSuperAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil & Configurações'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(_editing ? Icons.close : Icons.edit_outlined),
            onPressed: () => setState(() => _editing = !_editing),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => authProvider.verificarSessao(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primario, AppColors.primarioClaro],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSuperAdmin
                            ? Icons.admin_panel_settings
                            : Icons.person,
                        size: 44,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile?.nomeCompleto ?? 'Administrador',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primario,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSuperAdmin
                            ? AppColors.primarioClaro.withValues(alpha: 0.15)
                            : AppColors.cinzaClaro,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isSuperAdmin
                            ? 'Super Administrador'
                            : 'Administrador Nível 2',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSuperAdmin
                              ? AppColors.primario
                              : AppColors.cinza,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Dados pessoais',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primario,
                ),
              ),
              const SizedBox(height: 12),
              if (_editing) ...[
                TextFormField(
                  controller: _nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome completo',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _celularController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Número de celular',
                    prefixIcon: Icon(Icons.phone_android),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _salvarDados,
                  child: const Text('Salvar alterações'),
                ),
                const SizedBox(height: 14),
              ] else ...[
                _buildInfoRow(Icons.person_outline, 'Nome',
                    profile?.nomeCompleto ?? '—'),
                _buildInfoRow(Icons.phone_android, 'Celular',
                    profile?.celular ?? '—'),
                _buildInfoRow(
                    Icons.email_outlined, 'Email', profile?.email ?? '—'),
                _buildInfoRow(Icons.account_balance_outlined, 'Faculdade',
                    profile?.faculdade ?? '—'),
                _buildInfoRow(Icons.timelapse_outlined, 'Criado em',
                    Formatters.data(profile?.createdAt)),
              ],
              const SizedBox(height: 28),
              // Alterar senha
              const Text(
                'Alterar palavra-passe',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primario,
                ),
              ),
              const SizedBox(height: 12),
              _buildSenhaSection(),
              const SizedBox(height: 28),
              // Histórico de acessos pessoal
              ListTile(
                leading: Icon(
                  Icons.history_outlined,
                  color: AppColors.primario,
                ),
                title: const Text('Meu histórico de acessos'),
                subtitle: const Text('Ver os meus últimos acessos'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  widget.onNavigateTab?.call(4);
                },
              ),
              const Divider(height: 1),
              // Configurações globais (só super admin)
              if (isSuperAdmin) ...[
                const SizedBox(height: 16),
                const Text(
                  'Configurações globais do sistema',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primario,
                  ),
                ),
                const SizedBox(height: 12),
                _buildConfiguracaoGlobal(),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String valor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cinzaBorda),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primario),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.cinza),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSenhaSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cinzaBorda),
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _novaSenhaController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Nova palavra-passe',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _confirmarSenhaController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirmar palavra-passe',
              prefixIcon: Icon(Icons.lock_reset_outlined),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _alterarSenha,
            icon: const Icon(Icons.password_outlined),
            label: const Text('Alterar senha'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfiguracaoGlobal() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cinzaBorda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gerência do sistema',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ações disponíveis apenas para o Super Administrador.',
            style: TextStyle(fontSize: 12, color: AppColors.cinza),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.admin_panel_settings_outlined,
              color: AppColors.primario,
            ),
            title: const Text('Gerir administradores'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              widget.onNavigateTab?.call(3);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.bar_chart_outlined,
              color: AppColors.primario,
            ),
            title: const Text('Gerar relatórios'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              widget.onNavigateTab?.call(2);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.history_outlined,
              color: AppColors.primario,
            ),
            title: const Text('Histórico global de acessos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              widget.onNavigateTab?.call(4);
            },
          ),
        ],
      ),
    );
  }
}