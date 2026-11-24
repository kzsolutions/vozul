import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/denuncia_provider.dart';
import 'home_screen.dart';
import 'acompanhar_screen.dart';
import 'perfil_screen.dart';
import 'chat_list_student_screen.dart';
import 'denuncia_form_screen.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    HomeScreen(
      onAbrirMensagens: () => _navegarPara(1),
    ),
    const ChatListStudentScreen(),
    const AcompanharScreen(),
    const PerfilScreen(),
  ];

  void _navegarPara(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscreverNotificacoes();
      _carregarConversas();
    });
  }

  void _subscreverNotificacoes() {
    final userId = context.read<AuthProvider>().profile?.id;
    if (userId == null) return;

    final adminProvider = context.read<AdminProvider>();
    adminProvider.listarNotificacoes(userId);
    adminProvider.subscreverNotificacoes(userId);
  }

  /// Carrega as conversas para alimentar o badge de mensagens por ler.
  Future<void> _carregarConversas() async {
    final userId = context.read<AuthProvider>().profile?.id;
    if (userId == null) return;
    await context.read<DenunciaProvider>().listarMinhasDenuncias(userId);
  }

  @override
  Widget build(BuildContext context) {
    final naoLidas = context.select<DenunciaProvider, int>(
      (p) => p.totalNaoLidas,
    );

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DenunciaFormScreen(),
                  ),
                );
              },
              backgroundColor: AppColors.primario,
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              label: const Text(
                'Fazer Denúncia',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          // Ao abrir a aba Mensagens, o badge tem de reflectir o estado actual.
          if (index == 1) _carregarConversas();
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: naoLidas > 0,
              label: Text('$naoLidas'),
              child: const Icon(Icons.chat_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: naoLidas > 0,
              label: Text('$naoLidas'),
              child: const Icon(Icons.chat),
            ),
            label: 'Mensagens',
          ),
          const NavigationDestination(
            icon: Icon(Icons.track_changes_outlined),
            selectedIcon: Icon(Icons.track_changes),
            label: 'Acompanhar',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}