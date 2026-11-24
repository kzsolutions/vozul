import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_constants.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/denuncia_provider.dart';
import '../../models/denuncia.dart';
import '../../utils/formatters.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/empty_state.dart';
import 'denuncia_detail_screen.dart';

class DenunciasListScreen extends StatefulWidget {
  const DenunciasListScreen({super.key});

  @override
  State<DenunciasListScreen> createState() => _DenunciasListScreenState();
}

class _DenunciasListScreenState extends State<DenunciasListScreen> {
  final _buscaController = TextEditingController();
  String? _categoriaFiltro;
  String? _statusFiltro;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregar();
    });
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    final authProvider = context.read<AuthProvider>();
    final provider = context.read<DenunciaProvider>();
    final profile = authProvider.profile;

    final faculdade = profile?.isSuperAdmin == true ? null : profile?.faculdade;

    await provider.listarDenunciasAdmin(
      faculdade: faculdade,
      categoria: _categoriaFiltro,
      status: _statusFiltro,
      busca: _buscaController.text.trim(),
    );
  }

  void _aplicarFiltros() {
    setState(() {});
    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DenunciaProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Denúncias Recebidas'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: Column(
          children: [
            _buildFiltros(),
            const Divider(height: 1),
            Expanded(
              child: provider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primario,
                      ),
                    )
: provider.denunciasAdmin.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 80),
                                EmptyState(
                                  icon: Icons.inbox_outlined,
                                  mensagem: 'Nenhuma denúncia encontrada',
                                  subtitulo:
                                      'As denúncias recebidas aparecerão aqui.',
                                ),
                              ],
                            )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: provider.denunciasAdmin.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _DenunciaCard(
                              denuncia: provider.denunciasAdmin[index],
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DenunciaDetailScreen(
                                      denuncia: provider.denunciasAdmin[index],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _buscaController,
                  decoration: const InputDecoration(
                    hintText: 'Pesquisar (código, docente...)',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _aplicarFiltros(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _aplicarFiltros,
                icon: const Icon(Icons.filter_list),
                tooltip: 'Filtrar',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _categoriaFiltro,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Todas'),
                    ),
                    ...AppConstants.categoriasDenuncia
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                  ],
                  onChanged: (value) {
                    _categoriaFiltro = value;
                    _aplicarFiltros();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _statusFiltro,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Todos'),
                    ),
                    ...AppConstants.statusDenuncia
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s),
                            ))
                        .toList(),
                  ],
                  onChanged: (value) {
                    _statusFiltro = value;
                    _aplicarFiltros();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DenunciaCard extends StatelessWidget {
  final Denuncia denuncia;
  final VoidCallback onTap;

  const _DenunciaCard({required this.denuncia, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primario.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      denuncia.codigo,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primario,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const Spacer(),
                  StatusChip(status: denuncia.status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                denuncia.displayCategoria,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                denuncia.descricao,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.cinza,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _MetaItem(
                    icon: Icons.account_balance_outlined,
                    texto: denuncia.faculdade,
                  ),
                  _MetaItem(
                    icon: Icons.calendar_today_outlined,
                    texto: Formatters.data(denuncia.createdAt),
                  ),
                  if (denuncia.anonima)
                    const _MetaItem(
                      icon: Icons.security_outlined,
                      texto: 'Anónima',
                    ),
                  if (denuncia.temProvas)
                    const _MetaItem(
                      icon: Icons.attach_file,
                      texto: 'Com provas',
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

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String texto;

  const _MetaItem({required this.icon, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.cinza),
        const SizedBox(width: 4),
        Text(
          texto,
          style: const TextStyle(fontSize: 12, color: AppColors.cinza),
        ),
      ],
    );
  }
}