import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/denuncia.dart';
import '../../providers/auth_provider.dart';
import '../../providers/denuncia_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_chip.dart';
import 'chat_screen.dart';

class MinhasDenunciasScreen extends StatefulWidget {
  const MinhasDenunciasScreen({super.key});

  @override
  State<MinhasDenunciasScreen> createState() => _MinhasDenunciasScreenState();
}

class _MinhasDenunciasScreenState extends State<MinhasDenunciasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregar();
    });
  }

  Future<void> _carregar() async {
    final userId = context.read<AuthProvider>().profile?.id;
    if (userId != null) {
      await context.read<DenunciaProvider>().listarMinhasDenuncias(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DenunciaProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Denúncias'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: provider.carregandoMinhas
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primario),
              )
            : provider.minhasDenuncias.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 60),
                      EmptyState(
                        icon: Icons.inbox_outlined,
                        mensagem: 'Nenhuma denúncia registada',
                        subtitulo:
                            'Quando submeter uma denúncia, ela aparece aqui '
                            'para acompanhamento e conversa com a Comissão.',
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: provider.minhasDenuncias.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final d = provider.minhasDenuncias[index];
                      return _buildCard(context, d);
                    },
                  ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, Denuncia d) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChatScreen(denuncia: d)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    d.codigo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primario,
                      letterSpacing: 1,
                    ),
                  ),
                  StatusChip(status: d.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                d.displayCategoria,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${d.faculdade}${d.curso != null ? ' • ${d.curso}' : ''}'
                '${d.anonima ? ' • Anónima' : ''}',
                style: const TextStyle(fontSize: 12, color: AppColors.cinza),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: AppColors.cinza,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    Formatters.dataHora(d.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.cinza,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 16,
                    color: AppColors.primario,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Conversar',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primario,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}