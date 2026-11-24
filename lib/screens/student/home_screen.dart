import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_constants.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/denuncia_provider.dart';
import '../../utils/formatters.dart';
import '../auth/splash_screen.dart';
import 'denuncia_form_screen.dart';
import 'acompanhar_screen.dart';
import 'denuncias_minhas_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback? onAbrirMensagens;

  const HomeScreen({super.key, this.onAbrirMensagens});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profile = authProvider.profile;
    final adminProvider = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Início'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: adminProvider.naoLidas > 0,
              label: Text('${adminProvider.naoLidas}'),
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () => _mostrarNotificacoes(context, adminProvider),
          ),
        ],
      ),
      drawer: _buildDrawer(context, authProvider, profile?.nomeCompleto ?? ''),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSaudacao(profile?.nomeCompleto),
            const SizedBox(height: 16),
            _buildCardDenuncia(context),
            const SizedBox(height: 16),
            _buildCardAcompanhar(context),
            const SizedBox(height: 16),
            _buildCardMinhasDenuncias(context),
            const SizedBox(height: 24),
            const Text(
              'Tipos de denúncias',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primario,
              ),
            ),
            const SizedBox(height: 12),
            _buildCategoriasGrid(),
            const SizedBox(height: 24),
            _buildInfoAnonimato(),
          ],
        ),
      ),
    );
  }

  Widget _buildSaudacao(String? nome) {
    final saudacao = _saudacaoPorHora();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primario, AppColors.primarioClaro],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.campaign_outlined, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          Text(
            '$saudacao${nome != null && nome.isNotEmpty ? ', ${nome.split(' ').first}' : ''}!',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'A sua voz é importante. Denuncie com segurança.',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  String _saudacaoPorHora() {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'Bom dia';
    if (hora < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  Widget _buildCardDenuncia(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DenunciaFormScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primarioClaro.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.report_problem_outlined,
                  color: AppColors.primario,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fazer Denúncia',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primario,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Anónima ou identificada',
                      style: TextStyle(fontSize: 13, color: AppColors.cinza),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.cinza),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardAcompanhar(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AcompanharScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.verde.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.track_changes,
                  color: AppColors.verde,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Acompanhar Denúncia',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.verde,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Use o código UNI-XXXXX',
                      style: TextStyle(fontSize: 13, color: AppColors.cinza),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.cinza),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardMinhasDenuncias(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MinhasDenunciasScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.cinzaClaro,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.folder_open_outlined,
                  color: AppColors.cinza,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Minhas Denúncias',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.cinza,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ver o estado de todas as suas denúncias',
                      style: TextStyle(fontSize: 13, color: AppColors.cinza),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.cinza),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriasGrid() {
    final categorias = AppConstants.categoriasDenuncia;
    final icons = [
      Icons.person_off_outlined,
      Icons.currency_exchange_outlined,
      Icons.grade_outlined,
      Icons.people_outline,
      Icons.record_voice_over_outlined,
      Icons.warning_amber_outlined,
      Icons.workspace_premium_outlined,
      Icons.report_outlined,
      Icons.more_horiz,
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: categorias.length,
      itemBuilder: (context, index) {
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DenunciaFormScreen(categoriaPreSelecionada: categorias[index]),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cinzaBorda),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icons[index % icons.length],
                  color: AppColors.primario,
                  size: 26,
                ),
                const SizedBox(height: 8),
                Text(
                  categorias[index],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primario,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoAnonimato() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.verde.withValues(alpha: 0.3)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security_outlined, color: AppColors.verde, size: 22),
              SizedBox(width: 10),
              Text(
                'O seu anonimato está protegido',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.verde,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _InfoItem(
            icon: Icons.visibility_off_outlined,
            texto: 'Nenhuma denúncia anónima revela a sua identidade.',
          ),
          SizedBox(height: 8),
          _InfoItem(
            icon: Icons.vpn_lock_outlined,
            texto: 'O IP e a localização nunca são registados.',
          ),
          SizedBox(height: 8),
          _InfoItem(
            icon: Icons.token_outlined,
            texto: 'Cada denúncia gera um código único para acompanhamento.',
          ),
        ],
      ),
    );
  }

  void _mostrarNotificacoes(
      BuildContext context, AdminProvider adminProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        'Notificações',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      if (adminProvider.naoLidas > 0)
                        TextButton(
                          onPressed: () {
                            for (final n in adminProvider.notificacoes) {
                              if (n['lida'] != true) {
                                adminProvider
                                    .marcarNotificacaoLida(n['id'] as int);
                              }
                            }
                          },
                          child: const Text('Marcar todas como lidas'),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: adminProvider.notificacoes.isEmpty
                      ? const Center(
                          child: Text(
                            'Sem notificações',
                            style: TextStyle(color: AppColors.cinza),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: adminProvider.notificacoes.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final n = adminProvider.notificacoes[index];
                            return _NotificacaoTile(
                              titulo: n['titulo'] as String,
                              conteudo: n['conteudo'] as String,
                              lida: n['lida'] == true,
                              data: DateTime.tryParse(
                                  n['created_at'] as String? ?? ''),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider authProvider, String nome) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primario,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.campaign_outlined, color: Colors.white, size: 40),
                const SizedBox(height: 8),
                Text(
                  nome.isNotEmpty ? nome : 'Estudante',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.report_problem_outlined),
            title: const Text('Fazer Denúncia'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DenunciaFormScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.track_changes_outlined),
            title: const Text('Acompanhar Denúncia'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AcompanharScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder_open_outlined),
            title: const Text('Minhas Denúncias'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MinhasDenunciasScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat_outlined),
            title: const Text('Minhas Mensagens'),
            onTap: () {
              Navigator.pop(context);
              onAbrirMensagens?.call();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_outlined, color: AppColors.vermelho),
            title: const Text(
              'Sair',
              style: TextStyle(color: AppColors.vermelho),
            ),
            onTap: () async {
              await authProvider.logout();
              if (context.mounted) {
                context.read<DenunciaProvider>().limparSessao();
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const SplashScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String texto;

  const _InfoItem({required this.icon, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.verde),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(fontSize: 13, color: AppColors.cinza),
          ),
        ),
      ],
    );
  }
}

class _NotificacaoTile extends StatelessWidget {
  final String titulo;
  final String conteudo;
  final bool lida;
  final DateTime? data;

  const _NotificacaoTile({
    required this.titulo,
    required this.conteudo,
    required this.lida,
    this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: lida ? Colors.white : AppColors.primarioClaro.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: lida
              ? AppColors.cinzaBorda
              : AppColors.primario.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            lida ? Icons.notifications_none : Icons.notifications_active,
            color: lida ? AppColors.cinza : AppColors.primario,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        titulo,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              lida ? FontWeight.w600 : FontWeight.w800,
                        ),
                      ),
                    ),
                    if (data != null)
                      Text(
                        Formatters.dataHora(data!),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.cinza,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  conteudo,
                  style: const TextStyle(fontSize: 13, color: AppColors.cinza),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}