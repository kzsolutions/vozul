import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregar();
    });
  }

  Future<void> _carregar() async {
    final authProvider = context.read<AuthProvider>();
    final adminProvider = context.read<AdminProvider>();
    final profile = authProvider.profile;

    // Admin nível 2 vê apenas o seu histórico
    final usuarioId = profile?.isSuperAdmin == true ? null : profile?.id;

    await adminProvider.listarHistoricoAcessos(usuarioId: usuarioId);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().profile;
    final adminProvider = context.watch<AdminProvider>();
    final isSuperAdmin = profile?.isSuperAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Acessos'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: adminProvider.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primario),
              )
            : adminProvider.historicoAcessos.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 80),
                      EmptyState(
                        icon: Icons.history_outlined,
                        mensagem: 'Nenhum acesso registado',
                        subtitulo: 'O histórico de acessos aparece aqui.',
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: adminProvider.historicoAcessos.length,
                    itemBuilder: (context, index) {
                      final registro = adminProvider.historicoAcessos[index];
                      return _RegistroCard(
                        registro: registro,
                        mostrarUsuario: isSuperAdmin,
                      );
                    },
                  ),
      ),
    );
  }
}

class _RegistroCard extends StatelessWidget {
  final Map<String, dynamic> registro;
  final bool mostrarUsuario;

  const _RegistroCard({
    required this.registro,
    required this.mostrarUsuario,
  });

  @override
  Widget build(BuildContext context) {
    final acao = registro['acao'] as String? ?? 'Ação';
    final detalhes = registro['detalhes'] as String?;
    final ip = registro['ip_address'] as String?;
    final createdAt = registro['created_at'] != null
        ? DateTime.tryParse(registro['created_at'] as String)
        : null;
    final perfil = registro['profiles'] as Map<String, dynamic>?;
    final nomeUsuario = perfil?['nome_completo'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primarioClaro.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _iconeAcao(acao),
                color: AppColors.primario,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    acao,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (detalhes != null)
                    Text(
                      detalhes,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.cinza,
                      ),
                    ),
                  if (mostrarUsuario && nomeUsuario != null)
                    Text(
                      'Utilizador: $nomeUsuario',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.cinza,
                      ),
                    ),
                  if (mostrarUsuario && ip != null)
                    Text(
                      'IP: $ip',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.cinza,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.dataHora(createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.cinza,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconeAcao(String acao) {
    if (acao.contains('Dashboard')) return Icons.dashboard_outlined;
    if (acao.contains('Login')) return Icons.login_outlined;
    if (acao.contains('logout') || acao.contains('Sair')) {
      return Icons.logout_outlined;
    }
    if (acao.contains('Denúncia') || acao.contains('denúncia')) {
      return Icons.report_problem_outlined;
    }
    return Icons.access_time_outlined;
  }
}