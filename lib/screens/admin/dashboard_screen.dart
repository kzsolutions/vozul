import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/denuncia_provider.dart';
import '../../utils/formatters.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregar();
    });
  }

  Future<void> _carregar() async {
    final authProvider = context.read<AuthProvider>();
    final denunciaProvider = context.read<DenunciaProvider>();
    final adminProvider = context.read<AdminProvider>();

    final profile = authProvider.profile;
    final isAdmin = profile?.isAdminOuSuper ?? false;
    final isSuperAdmin = profile?.isSuperAdmin ?? false;

    // Estatísticas (filtradas por faculdade para admin nível 2)
    if (isAdmin) {
      await denunciaProvider.carregarEstatisticas(
        faculdade: isSuperAdmin ? null : profile?.faculdade,
      );
    }

    // Registrar acesso
    if (profile != null) {
      await adminProvider.registrarAcesso(
        usuarioId: profile.id,
        acao: 'Acesso ao Dashboard',
      );
    }

    // Notificações
    if (profile != null) {
      await adminProvider.listarNotificacoes(profile.id);
    }
  }

  void _mostrarNotificacoes(
      BuildContext context, AdminProvider adminProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
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
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final n = adminProvider.notificacoes[index];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: n['lida'] == true
                                    ? Colors.white
                                    : AppColors.primarioClaro
                                        .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: n['lida'] == true
                                      ? AppColors.cinzaBorda
                                      : AppColors.primario
                                          .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    n['lida'] == true
                                        ? Icons.notifications_none
                                        : Icons.notifications_active,
                                    color: n['lida'] == true
                                        ? AppColors.cinza
                                        : AppColors.primario,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                n['titulo'] as String,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: n['lida'] == true
                                                      ? FontWeight.w600
                                                      : FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                            if (n['created_at'] != null)
                                              Text(
                                                Formatters.dataHora(
                                                    DateTime.tryParse(
                                                        n['created_at'] as String) ??
                                                        DateTime.now()),
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: AppColors.cinza,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          n['conteudo'] as String,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.cinza,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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

  @override
  Widget build(BuildContext context) {
    final denunciaProvider = context.watch<DenunciaProvider>();
    final adminProvider = context.watch<AdminProvider>();

    final stats = denunciaProvider.estatisticas;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
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
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: denunciaProvider.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primario),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatCards(stats),
                    const SizedBox(height: 20),
                    _buildStatusRow(stats),
                    const SizedBox(height: 20),
                    _buildCategoriasChart(stats),
                    const SizedBox(height: 20),
                    _buildMensalChart(stats),
                    const SizedBox(height: 20),
                    _buildFaculdades(stats),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatCards(Map<String, dynamic> stats) {
    final total = stats['total'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            titulo: 'Total',
            valor: '$total',
            icone: Icons.summarize_outlined,
            cor: AppColors.primario,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            titulo: 'Recebidas',
            valor: '${stats['por_status']?['Recebida'] ?? 0}',
            icone: Icons.mark_email_read_outlined,
            cor: AppColors.statusRecebida,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            titulo: 'Em análise',
            valor: '${stats['por_status']?['Em análise'] ?? 0}',
            icone: Icons.manage_search_outlined,
            cor: AppColors.statusEmAnalise,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(Map<String, dynamic> stats) {
    final porStatus = stats['por_status'] as Map<String, dynamic>? ?? {};

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            titulo: 'Investigação',
            valor: '${porStatus['Investigação'] ?? 0}',
            icone: Icons.fact_check_outlined,
            cor: AppColors.statusInvestigacao,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            titulo: 'Resolvidas',
            valor: '${porStatus['Resolvida'] ?? 0}',
            icone: Icons.check_circle_outline,
            cor: AppColors.statusResolvida,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            titulo: 'Encerradas',
            valor: '${porStatus['Encerrada'] ?? 0}',
            icone: Icons.lock_outline,
            cor: AppColors.statusEncerrada,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriasChart(Map<String, dynamic> stats) {
    final porCategoria = stats['por_categoria'] as Map<String, dynamic>? ?? {};

    if (porCategoria.isEmpty) {
      return const _EmptySection('Sem dados de categorias');
    }

    final sorted = porCategoria.entries.toList()
      ..sort((a, b) => (b.value).compareTo(a.value));
    final top = sorted.take(5).toList();

    return _ChartCard(
      titulo: 'Categorias mais frequentes',
      child: Column(
        children: top.map((entry) {
          final total = porCategoria.values.fold<int>(
            0,
            (sum, v) => sum + (v as int),
          );
          final pct = (entry.value as int) / total;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 130,
                  child: Text(
                    entry.key,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor: AppColors.cinzaClaro,
                      color: AppColors.primarioClaro,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 32,
                  child: Text(
                    '${(pct * 100).toStringAsFixed(0)}%',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.cinza,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMensalChart(Map<String, dynamic> stats) {
    final porMes = stats['por_mes'] as Map<String, dynamic>? ?? {};

    if (porMes.isEmpty) {
      return const _EmptySection('Sem dados mensais');
    }

    // Ordenar por mês
    final chaves = porMes.keys.toList()..sort();

    final pontos = chaves.asMap().entries.map((entry) {
      final index = entry.key;
      final chave = entry.value;
      final valor = porMes[chave] as int;
      return FlSpot(index.toDouble(), valor.toDouble());
    }).toList();

    // Labels mensais compactos
    final labels = chaves.map((chave) {
      final partes = chave.split('-');
      return '${partes[1]}/${partes[0].substring(2)}';
    }).toList();

    return _ChartCard(
      titulo: 'Evolução mensal',
      child: SizedBox(
        height: 160,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: (porMes.values.map((v) => v as int).fold<int>(0, max) + 1)
                .toDouble(),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final label = chaveMes(chaves[group.x.toInt()]);
                  return BarTooltipItem(
                    '$label\n${rod.toY.round()} denúncias',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= labels.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        labels[index],
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.cinza,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: const FlGridData(
              show: true,
              drawVerticalLine: false,
            ),
            borderData: FlBorderData(show: false),
            barGroups: pontos.asMap().entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value.y,
                    color: AppColors.primarioClaro,
                    width: 10,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  String chaveMes(String chave) {
    final partes = chave.split('-');
    final mes = int.tryParse(partes[1]) ?? 1;
    final meses = [
      '', 'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set',
      'Out', 'Nov', 'Dez',
    ];
    return '${meses[mes]} ${partes[0]}';
  }

  Widget _buildFaculdades(Map<String, dynamic> stats) {
    final porFaculdade = stats['por_faculdade'] as Map<String, dynamic>? ?? {};

    if (porFaculdade.isEmpty) {
      return const SizedBox.shrink();
    }

    final sorted = porFaculdade.entries.toList()
      ..sort((a, b) => (b.value).compareTo(a.value));

    return _ChartCard(
      titulo: 'Faculdades com mais casos',
      child: Column(
        children: sorted.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_outlined,
                  size: 16,
                  color: AppColors.primario,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.key,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Text(
                  '${entry.value}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primario,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;
  final Color cor;

  const _StatCard({
    required this.titulo,
    required this.valor,
    required this.icone,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cinzaBorda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: cor, size: 20),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: cor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppColors.cinza),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String titulo;
  final Widget child;

  const _ChartCard({required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
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
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primario,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String mensagem;

  const _EmptySection(this.mensagem);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cinzaBorda),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.cinza, size: 18),
          const SizedBox(width: 8),
          Text(
            mensagem,
            style: const TextStyle(fontSize: 13, color: AppColors.cinza),
          ),
        ],
      ),
    );
  }
}