import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../auth/splash_screen.dart';
import 'dashboard_screen.dart';
import 'denuncias_list_screen.dart';
import 'relatorios_screen.dart';
import 'admins_screen.dart';
import 'historico_screen.dart';
import 'profile_screen.dart';
import 'chat_list_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  void _navegarPara(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscreverNotificacoes();
    });
  }

  void _subscreverNotificacoes() {
    final userId = context.read<AuthProvider>().profile?.id;
    if (userId == null) return;

    final adminProvider = context.read<AdminProvider>();
    adminProvider.listarNotificacoes(userId);
    adminProvider.subscreverNotificacoes(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const DashboardScreen(),
          const DenunciasListScreen(),
          const RelatoriosScreen(),
          const AdminsScreen(),
          const HistoricoScreen(),
          const ChatListScreen(),
          ProfileScreen(
            onNavigateTab: _navegarPara,
            onLogout: _logout,
          ),
        ],
      ),
      drawer: _AdminDrawer(
        currentIndex: _currentIndex,
        onSelect: _navegarPara,
        onLogout: _logout,
      ),
    );
  }

  void _logout() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    }
  }
}

class _AdminDrawer extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  const _AdminDrawer({
    required this.currentIndex,
    required this.onSelect,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().profile;
    final isSuperAdmin = profile?.isSuperAdmin ?? false;

    final icones = [
      Icons.dashboard_outlined,
      Icons.report_problem_outlined,
      Icons.bar_chart_outlined,
      Icons.admin_panel_settings_outlined,
      Icons.history_outlined,
      Icons.chat_outlined,
      Icons.person_outline,
    ];

    final titulos = [
      'Dashboard',
      'Denúncias Recebidas',
      'Relatórios',
      'Administradores',
      'Histórico de Acessos',
      'Mensagens',
      'Perfil & Configurações',
    ];

    final visiveis = [true, true, true, isSuperAdmin, true, true, true];

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primario, AppColors.primarioClaro],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: AppColors.primario,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile?.nomeCompleto ?? 'Administrador',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              isSuperAdmin
                                  ? 'Super Administrador'
                                  : 'Administrador Nível 2',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: titulos.length,
                itemBuilder: (context, index) {
                  if (!visiveis[index]) return const SizedBox.shrink();
                  final isAtivo = currentIndex == index;

                  return ListTile(
                    leading: Icon(icones[index]),
                    title: Text(titulos[index]),
                    selected: isAtivo,
                    selectedTileColor:
                        AppColors.primario.withValues(alpha: 0.06),
                    selectedColor: AppColors.primario,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onSelect(index);
                    },
                  );
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_outlined, color: AppColors.vermelho),
              title: const Text(
                'Sair',
                style: TextStyle(color: AppColors.vermelho),
              ),
              onTap: () {
                Navigator.pop(context);
                onLogout();
              },
            ),
          ],
        ),
      ),
    );
  }
}