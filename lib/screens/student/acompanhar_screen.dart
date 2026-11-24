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
import '../student/chat_screen.dart';

class AcompanharScreen extends StatefulWidget {
  const AcompanharScreen({super.key});

  @override
  State<AcompanharScreen> createState() => _AcompanharScreenState();
}

class _AcompanharScreenState extends State<AcompanharScreen> {
  final _codigoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().profile?.id;
      if (userId != null) {
        final provider = context.read<DenunciaProvider>();
        provider.listarMinhasDenuncias(userId);
        provider.carregarCodigosGuardados(userId);
      }
    });
  }

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    final codigo = _codigoController.text.trim();
    if (codigo.isEmpty) return;

    FocusScope.of(context).unfocus();
    final provider = context.read<DenunciaProvider>();
    await provider.buscarPorCodigo(codigo);

    if (!mounted) return;

    if (provider.denunciaAtual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Código não encontrado'),
          backgroundColor: provider.codigosBloqueados
              ? AppColors.amarelo
              : AppColors.vermelho,
          duration: provider.codigosBloqueados
              ? const Duration(seconds: 6)
              : const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DenunciaProvider>();
    final denuncia = provider.denunciaAtual;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Acompanhar Denúncia'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Insira o código da denúncia',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primario,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'O código de acompanhamento está no comprovativo de submissão. '
              'Em denúncias anónimas funciona como credencial de acesso.',
              style: TextStyle(fontSize: 13, color: AppColors.cinza),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codigoController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Código (ex: UNI-58392)',
                      prefixIcon: Icon(Icons.token_outlined),
                      hintText: 'UNI-',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: provider.isLoading ? null : _buscar,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(56, 56),
                    padding: const EdgeInsets.all(0),
                  ),
                  child: provider.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.search),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (denuncia != null) _buildResultado(denuncia),
            if (provider.codigosGuardados.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildCodigosGuardados(provider),
            ],
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'As suas denúncias',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primario,
              ),
            ),
            const SizedBox(height: 12),
            _buildMinhasDenunciasResumo(context),
          ],
        ),
      ),
    );
  }

  Widget _buildResultado(Denuncia denuncia) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primarioClaro),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                denuncia.codigo,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primario,
                  letterSpacing: 1,
                ),
              ),
              StatusChip(status: denuncia.status),
            ],
          ),
          const SizedBox(height: 12),
          _buildTimeline(denuncia.status),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          _DetalheLinha(
            icon: Icons.category_outlined,
            label: 'Tipo',
            valor: denuncia.displayCategoria,
          ),
          _DetalheLinha(
            icon: Icons.account_balance_outlined,
            label: 'Faculdade',
            valor: denuncia.faculdade,
          ),
          _DetalheLinha(
            icon: Icons.school_outlined,
            label: 'Curso',
            valor: denuncia.curso ?? '—',
          ),
          _DetalheLinha(
            icon: Icons.calendar_today_outlined,
            label: 'Data do ocorrido',
            valor: Formatters.data(denuncia.dataOcorrido),
          ),
          _DetalheLinha(
            icon: Icons.location_on_outlined,
            label: 'Local',
            valor: denuncia.localOcorrido ?? '—',
          ),
          _DetalheLinha(
            icon: Icons.flag_outlined,
            label: 'Data de envio',
            valor: Formatters.dataHora(denuncia.createdAt),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(denuncia: denuncia),
                ),
              );
            },
            icon: const Icon(Icons.chat_outlined),
            label: const Text('Conversar com a Comissão'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(String statusAtual) {
    final statuses = AppConstants.statusDenuncia;
    final currentIndex = statuses.indexOf(statusAtual);

    return Column(
      children: List.generate(statuses.length, (index) {
        final status = statuses[index];
        final cor = Formatters.corStatus(status);
        final concluido = index <= currentIndex;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: concluido ? cor : AppColors.cinzaClaro,
                    border: Border.all(
                      color: concluido ? cor : AppColors.cinzaBorda,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    concluido ? Icons.check : Icons.circle,
                    size: 11,
                    color: concluido ? Colors.white : AppColors.cinza,
                  ),
                ),
                if (index < statuses.length - 1)
                  Container(
                    width: 2,
                    height: 28,
                    color: index < currentIndex
                        ? cor
                        : AppColors.cinzaBorda,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 3, bottom: 10),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: index == currentIndex
                      ? FontWeight.w800
                      : FontWeight.w500,
                  color: concluido ? cor : AppColors.cinza,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildCodigosGuardados(DenunciaProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Denúncias guardadas',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primario,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Códigos das suas denúncias anónimas neste dispositivo. '
          'Toque para acompanhar; pode removê-los quando quiser.',
          style: TextStyle(fontSize: 12, color: AppColors.cinza),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: provider.codigosGuardados.map((codigo) {
            return InputChip(
              label: Text(
                codigo,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              avatar: const Icon(Icons.token_outlined, size: 18),
              onPressed: () async {
                _codigoController.text = codigo;
                await _buscar();
              },
              onDeleted: () {
                final userId = context.read<AuthProvider>().profile?.id;
                if (userId != null) {
                  provider.removerCodigoGuardado(userId, codigo);
                }
              },
              deleteIconColor: AppColors.cinza,
              side: BorderSide(color: AppColors.primarioClaro),
              backgroundColor: Colors.white,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMinhasDenunciasResumo(BuildContext context) {
    final userId = context.read<AuthProvider>().profile?.id;

    if (userId == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: EmptyState(
          icon: Icons.inbox_outlined,
          mensagem: 'Sessão não disponível',
          subtitulo: 'Entre novamente na sua conta para ver as suas denúncias.',
        ),
      );
    }

    // Carregar denúncias na primeira vez (feito no initState)
    final provider = context.watch<DenunciaProvider>();

    if (provider.carregandoMinhas) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primario),
        ),
      );
    }

    if (provider.minhasDenuncias.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: EmptyState(
          icon: Icons.inbox_outlined,
          mensagem: 'Nenhuma denúncia encontrada',
          subtitulo:
              'As suas denúncias, identificadas e anónimas, aparecem aqui '
              'para acompanhamento.',
        ),
      );
    }

    return Column(
      children: provider.minhasDenuncias
          .map((d) => Card(
                child: ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Formatters.corStatus(d.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Formatters.iconeStatus(d.status),
                      color: Formatters.corStatus(d.status),
                    ),
                  ),
                  title: Text(
                    '${d.codigo} — ${d.displayCategoria}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${d.faculdade}\nEnviada: ${Formatters.data(d.createdAt)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: StatusChip(status: d.status),
                  isThreeLine: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(denuncia: d),
                      ),
                    );
                  },
                ),
              ))
          .toList()
          .cast<Widget>(),
    );
  }
}

class _DetalheLinha extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valor;

  const _DetalheLinha({
    required this.icon,
    required this.label,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.cinza),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.cinza),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}