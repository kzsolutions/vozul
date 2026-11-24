import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/profile.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/catalogo_service.dart';
import '../../widgets/empty_state.dart';

class AdminsScreen extends StatefulWidget {
  const AdminsScreen({super.key});

  @override
  State<AdminsScreen> createState() => _AdminsScreenState();
}

class _AdminsScreenState extends State<AdminsScreen> {
  final _catalogoService = CatalogoService();
  List<Polo> _polos = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().listarAdmins();
    });
    _carregarPolos();
  }

  Future<void> _carregarPolos() async {
    final leitura = await _catalogoService.listarPolos();
    if (!mounted) return;
    setState(() => _polos = leitura.itens);
  }

  String _nomePolo(String? id) {
    if (id == null) return '';
    for (final polo in _polos) {
      if (polo.id == id) return polo.nome;
    }
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().profile;
    final isSuperAdmin = profile?.isSuperAdmin ?? false;

    if (!isSuperAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Administradores'),
          automaticallyImplyLeading: false,
        ),
        body: const EmptyState(
          icon: Icons.lock_outline,
          mensagem: 'Acesso restrito',
          subtitulo:
              'Apenas o Super Administrador pode gerir administradores.',
        ),
      );
    }

    final adminProvider = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administradores'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: () => adminProvider.listarAdmins(),
        child: adminProvider.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primario),
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 100),
                children: [
                  // Lista de admins
                  for (final admin in adminProvider.admins)
                    _AdminCard(
                      admin: admin,
                      poloNome: _nomePolo(admin.poloId),
                      onRemover: admin.id != profile?.id
                          ? () => _confirmarRemocao(admin)
                          : null,
                      onMudarNivel: admin.id != profile?.id
                          ? (novoNivel) =>
                              _mudarNivel(admin, novoNivel)
                          : null,
                    ),
                  if (adminProvider.admins.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: EmptyState(
                        icon: Icons.admin_panel_settings_outlined,
                        mensagem: 'Nenhum administrador',
                        subtitulo: 'Use o botão abaixo para adicionar.',
                      ),
                    ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _adicionarAdmin,
        backgroundColor: AppColors.primario,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_outlined),
        label: const Text('Adicionar Administrador'),
      ),
    );
  }

  Future<void> _adicionarAdmin() async {
    // Formulário para adicionar admin
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AdicionarAdminSheet(),
    );

    if (mounted) {
      await context.read<AdminProvider>().listarAdmins();
    }
  }

  Future<void> _confirmarRemocao(Profile admin) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover administrador'),
        content: Text(
          'Deseja realmente remover ${admin.nomeCompleto ?? admin.email ?? 'este administrador'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Remover',
              style: TextStyle(color: AppColors.vermelho),
            ),
          ),
        ],
      ),
    );

    if (confirmado == true && mounted) {
      final provider = context.read<AdminProvider>();
      await provider.removerAdmin(admin.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${admin.nomeCompleto} removido')),
        );
      }
    }
  }

  Future<void> _mudarNivel(Profile admin, String novoNivel) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar nível'),
        content: Text(
          'Alterar ${admin.nomeCompleto ?? admin.email ?? 'admin'} para '
          '${novoNivel == 'super_admin' ? 'Super Administrador' : 'Administrador Nível 2'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Alterar'),
          ),
        ],
      ),
    );

    if (confirmado == true && mounted) {
      final provider = context.read<AdminProvider>();
      await provider.atualizarNivelAdmin(admin.id, novoNivel);
    }
  }
}

class _AdminCard extends StatelessWidget {
  final Profile admin;
  final String poloNome;
  final VoidCallback? onRemover;
  final ValueChanged<String>? onMudarNivel;

  const _AdminCard({
    required this.admin,
    required this.poloNome,
    this.onRemover,
    this.onMudarNivel,
  });

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = admin.isSuperAdmin;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isSuperAdmin
                          ? [AppColors.primario, AppColors.primarioClaro]
                          : [AppColors.cinza, AppColors.cinzaClaro],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSuperAdmin
                        ? Icons.admin_panel_settings
                        : Icons.person_outline,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        admin.nomeCompleto ?? 'Sem nome',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isSuperAdmin
                            ? 'Super Administrador'
                            : 'Administrador Nível 2',
                        style: TextStyle(
                          fontSize: 12,
                          color: isSuperAdmin
                              ? AppColors.primario
                              : AppColors.cinza,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Ações
                PopupMenuButton<String>(
                  onSelected: (valor) {
                    if (valor == 'remover') {
                      onRemover?.call();
                    } else if (valor == 'nivel2') {
                      onMudarNivel?.call('admin');
                    } else if (valor == 'superior') {
                      onMudarNivel?.call('super_admin');
                    }
                  },
                  itemBuilder: (context) => [
                    if (onMudarNivel != null && !isSuperAdmin)
                      const PopupMenuItem(
                        value: 'superior',
                        child: Text('Promover a Superior'),
                      ),
                    if (onMudarNivel != null && isSuperAdmin)
                      const PopupMenuItem(
                        value: 'nivel2',
                        child: Text('Rebaixar para Nível 2'),
                      ),
                    if (onRemover != null)
                      PopupMenuItem(
                        value: 'remover',
                        child: const Text(
                          'Remover',
                          style: TextStyle(color: AppColors.vermelho),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.email_outlined,
              valor: admin.email ?? '—',
            ),
            if (admin.celular != null)
              _InfoRow(
                icon: Icons.phone_android,
                valor: admin.celular!,
              ),
            if (admin.isAdmin && poloNome.isNotEmpty)
              _InfoRow(
                icon: Icons.location_on_outlined,
                valor: poloNome,
              ),
            if (admin.faculdade != null)
              _InfoRow(
                icon: Icons.account_balance_outlined,
                valor: admin.faculdade!,
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String valor;

  const _InfoRow({required this.icon, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.cinza),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(fontSize: 13, color: AppColors.cinza),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdicionarAdminSheet extends StatefulWidget {
  @override
  State<_AdicionarAdminSheet> createState() => _AdicionarAdminSheetState();
}

class _AdicionarAdminSheetState extends State<_AdicionarAdminSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _celularController = TextEditingController();
  final _senhaController = TextEditingController();
  String? _nivel = 'admin';
  String? _poloId;
  String? _faculdade;

  // O âmbito do administrador é a faculdade dentro da delegação: a mesma
  // faculdade existe em mais do que um pólo, por isso a lista é sempre
  // filtrada pelo campus escolhido.
  final _catalogoService = CatalogoService();
  List<Polo> _polos = const [];
  List<Faculdade> _faculdades = const [];

  @override
  void initState() {
    super.initState();
    _carregarPolos();
  }

  Future<void> _carregarPolos() async {
    final leitura = await _catalogoService.listarPolos();
    if (!mounted) return;
    setState(() => _polos = leitura.itens);
  }

  Future<void> _carregarFaculdades(String poloId) async {
    final leitura = await _catalogoService.listarFaculdades(poloId);
    if (!mounted) return;
    setState(() => _faculdades = leitura.itens);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _celularController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final role = _nivel ?? 'admin';
    if (role == 'admin' && (_poloId == null || _faculdade == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione a delegação e a faculdade do administrador'),
          backgroundColor: AppColors.vermelho,
        ),
      );
      return;
    }

    final provider = context.read<AdminProvider>();
    final sucesso = await provider.criarAdmin(
      email: _emailController.text.trim(),
      password: _senhaController.text,
      nomeCompleto: _nomeController.text.trim(),
      celular: _celularController.text.trim(),
      faculdade: role == 'admin' ? _faculdade : null,
      poloId: role == 'admin' ? _poloId : null,
      role: role,
    );

    if (!mounted) return;

    if (sucesso) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Administrador adicionado com sucesso')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Erro ao adicionar administrador'),
          backgroundColor: AppColors.vermelho,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Adicionar Administrador',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primario,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome completo',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Nome obrigatório' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email obrigatório';
                  if (!v.contains('@')) return 'Email inválido';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _celularController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Número de celular',
                  prefixIcon: Icon(Icons.phone_android),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Celular obrigatório';
                  }
                  if (!_celularValido(v)) return 'Celular inválido';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _senhaController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Senha inicial',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (v) =>
                    v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _nivel,
                decoration: const InputDecoration(
                  labelText: 'Nível',
                  prefixIcon: Icon(Icons.security_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Nível 2')),
                  DropdownMenuItem(
                    value: 'super_admin',
                    child: Text('Super Administrador'),
                  ),
                ],
                onChanged: (value) => setState(() {
                  _nivel = value;
                  if (value != 'admin') {
                    _poloId = null;
                    _faculdade = null;
                    _faculdades = const [];
                  }
                }),
              ),
              const SizedBox(height: 14),
              if (_nivel == 'admin') ...[
                DropdownButtonFormField<String>(
                  value: _poloId,
                  decoration: const InputDecoration(
                    labelText: 'Delegação',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  items: _polos
                      .map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(
                              p.rotulo,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _poloId = value;
                      _faculdade = null;
                      _faculdades = const [];
                    });
                    _carregarFaculdades(value);
                  },
                  hint: const Text('Selecione a delegação'),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _faculdade,
                  decoration: const InputDecoration(
                    labelText: 'Faculdade',
                    prefixIcon: Icon(Icons.account_balance_outlined),
                  ),
                  items: _faculdades
                      .map((f) => DropdownMenuItem(
                            value: f.nome,
                            child: Text(
                              f.nome,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: _poloId == null
                      ? null
                      : (value) => setState(() => _faculdade = value),
                  hint: Text(
                    _poloId == null
                        ? 'Escolha primeiro a delegação'
                        : 'Selecione a faculdade',
                  ),
                  validator: (v) =>
                      v == null ? 'Faculdade obrigatória' : null,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Este administrador verá apenas as denúncias desta '
                  'faculdade na delegação selecionada e ficará responsável '
                  'pelas que ainda não tenham responsável.',
                  style: TextStyle(fontSize: 11, color: AppColors.cinza),
                ),
              ] else
                const Text(
                  'Super Administradores têm acesso global a todas as '
                  'delegações e faculdades.',
                  style: TextStyle(fontSize: 12, color: AppColors.cinza),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _salvar,
                child: const Text('Adicionar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _celularValido(String valor) {
  final digitos = valor.replaceAll(RegExp(r'\D'), '');
  if (digitos.startsWith('258')) {
    return RegExp(r'^2588[2-7]\d{7}$').hasMatch(digitos);
  }
  return RegExp(r'^8[2-7]\d{7}$').hasMatch(digitos);
}