import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/denuncia_provider.dart';
import '../../services/catalogo_service.dart';
import '../../services/validacao_service.dart';
import '../../utils/formatters.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool _editing = false;
  final _nomeController = TextEditingController();
  final _celularController = TextEditingController();
  String? _faculdade;
  String? _curso;
  bool _aValidar = false;

  final _catalogoService = CatalogoService();

  // Catalogo do campus do perfil. Uma conta criada com a validacao pendente
  // fica sem campus, e nesse caso o estudante escolhe o seu antes de validar.
  List<Polo> _polos = const [];
  List<Faculdade> _faculdades = const [];
  List<Curso> _cursos = const [];
  String? _polo;
  bool _aCarregarCatalogo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = context.read<AuthProvider>().profile;
      if (profile != null) {
        _nomeController.text = profile.nomeCompleto ?? '';
        _celularController.text = profile.celular ?? '';
        _faculdade = profile.faculdade;
        _curso = profile.curso;
        _polo = profile.poloId;
      }
      _carregarCatalogo();
    });
  }

  Future<void> _carregarCatalogo() async {
    final leitura = await _catalogoService.listarPolos();
    if (!mounted) return;

    setState(() {
      _polos = leitura.itens;
      _polo ??= leitura.itens.isNotEmpty ? leitura.itens.first.id : null;
    });

    final polo = _polo;
    if (polo != null) await _carregarFaculdades(polo);
  }

  Future<void> _carregarFaculdades(String poloId) async {
    setState(() => _aCarregarCatalogo = true);
    final leitura = await _catalogoService.listarFaculdades(poloId);
    if (!mounted) return;
    setState(() {
      _faculdades = leitura.itens;
      _aCarregarCatalogo = false;
    });
  }

  Future<void> _carregarCursos(String faculdadeId) async {
    setState(() {
      _aCarregarCatalogo = true;
      _cursos = const [];
    });
    final leitura = await _catalogoService.listarCursos(faculdadeId);
    if (!mounted) return;
    setState(() {
      _cursos = leitura.itens;
      _aCarregarCatalogo = false;
    });
  }

  String? _idFaculdade(String? nome) {
    for (final f in _faculdades) {
      if (f.nome == nome) return f.id;
    }
    return null;
  }

  void _mudarPolo(String? poloId) {
    setState(() {
      _polo = poloId;
      _faculdade = null;
      _curso = null;
      _faculdades = const [];
      _cursos = const [];
    });
    if (poloId != null) _carregarFaculdades(poloId);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _celularController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final authProvider = context.read<AuthProvider>();

    // O campus nao e enviado: e o servidor que o atribui, a partir da
    // validacao academica (trigger proteger_colunas_perfil recusa que o
    // proprio estudante escreva o polo_id). Alterar o campus faz-se na
    // validacao, nao aqui.
    await authProvider.atualizarProfile({
      'nome_completo': _nomeController.text.trim(),
      'celular': _celularController.text.trim(),
      'faculdade': _faculdade,
      'curso': _curso,
    });

    if (mounted) {
      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado com sucesso')),
      );
    }
  }

  /// Concluir a validação académica de uma conta criada em modo pendente.
  ///
  /// Primeiro volta a consultar a fonte (a Edge Function grava a validação) e só
  /// depois pede ao servidor que a aplique ao perfil. Se a universidade ainda
  /// estiver indisponível, o perfil continua pendente e o estudante é avisado.
  Future<void> _validarAgora() async {
    final profile = context.read<AuthProvider>().profile;
    final numero = profile?.numeroEstudante;
    if (numero == null || numero.isEmpty) return;

    setState(() => _aValidar = true);

    final service = ValidacaoService();
    // A consulta e feita para o campus do perfil: e a lista desse campus que a
    // faculdade e o curso tem de conter.
    final resultado = await service.validar(numero: numero, polo: _polo);
    var aplicado = false;

    if (resultado.confirmado) {
      aplicado = await service.aplicarValidacaoAoPerfil(polo: _polo);
      if (aplicado && mounted) {
        await context.read<AuthProvider>().recarregarProfile();
      }
    }

    if (!mounted) return;
    setState(() => _aValidar = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          aplicado
              ? 'Número de estudante validado.'
              : resultado.pendente
                  ? 'A universidade continua indisponível. Tente novamente mais tarde.'
                  : resultado.mensagem,
        ),
        backgroundColor: aplicado ? AppColors.verde : AppColors.amarelo,
      ),
    );
  }

  Future<void> _logout() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();
    if (!mounted) return;
    context.read<DenunciaProvider>().limparSessao();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(_editing ? Icons.close : Icons.edit_outlined),
            onPressed: () => setState(() => _editing = !_editing),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar
            Center(
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primario, AppColors.primarioClaro],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile?.nomeCompleto ?? 'Estudante',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primario,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Estudante',
                    style: TextStyle(fontSize: 13, color: AppColors.cinza),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            if (_editing) ...[
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome completo',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _celularController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Número de celular',
                  prefixIcon: Icon(Icons.phone_android),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _polo,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Campus / delegação',
                  prefixIcon: Icon(Icons.location_city_outlined),
                  helperText:
                      'Definido pela validação na universidade. Altere-o aqui '
                      'apenas se ainda não validou o número.',
                  helperMaxLines: 3,
                ),
                items: _polos
                    .map((p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(p.rotulo, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                // So enquanto a conta estiver pendente e faz sentido mudar:
                // depois de validado, o campus fica preso ao que a
                // universidade registou.
                onChanged: _aCarregarCatalogo ||
                        (profile?.temValidacao ?? false)
                    ? null
                    : _mudarPolo,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _faculdade,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Faculdade',
                  prefixIcon: Icon(Icons.account_balance_outlined),
                ),
                items: _faculdades
                    .map((f) => DropdownMenuItem(
                          value: f.nome,
                          child: Text(f.nome, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: _aCarregarCatalogo
                    ? null
                    : (value) {
                        setState(() {
                          _faculdade = value;
                          _curso = null;
                        });
                        final id = _idFaculdade(value);
                        if (id != null) _carregarCursos(id);
                      },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _curso,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Curso',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                items: _cursos
                    .map((c) => DropdownMenuItem(
                          value: c.nome,
                          child: Text(c.nome, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: _faculdade == null
                    ? null
                    : (value) => setState(() => _curso = value),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _salvar,
                child: const Text('Salvar alterações'),
              ),
            ] else ...[
              _buildValidacaoCard(profile),
              _buildInfoCard(
                Icons.badge_outlined,
                'Número de estudante',
                profile?.numeroEstudante ?? '—',
              ),
              _buildInfoCard(
                Icons.phone_android,
                'Celular',
                profile?.celular ?? '—',
              ),
              _buildInfoCard(
                Icons.email_outlined,
                'Email',
                profile?.email ?? '—',
              ),
              _buildInfoCard(
                Icons.account_balance_outlined,
                'Faculdade',
                profile?.faculdade ?? '—',
              ),
              _buildInfoCard(
                Icons.school_outlined,
                'Curso',
                profile?.curso ?? '—',
              ),
              _buildInfoCard(
                Icons.calendar_today_outlined,
                'Registado em',
                Formatters.data(profile?.createdAt),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Estado da validação académica, com a forma de concluir a validação quando a
  /// conta ficou pendente.
  Widget _buildValidacaoCard(Profile? profile) {
    if (profile == null) return const SizedBox.shrink();

    final validado = profile.temValidacao;
    final origem = profile.numeroValidadoOrigem;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: validado ? AppColors.verdeClaro : AppColors.amareloClaro,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: validado ? AppColors.verde : AppColors.amarelo,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                validado ? Icons.verified_outlined : Icons.info_outline,
                color: validado ? AppColors.verde : AppColors.amarelo,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  validado
                      ? 'Número de estudante validado'
                      : 'Validação por concluir',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: validado ? AppColors.verde : AppColors.amarelo,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            validado
                ? (origem == 'mock'
                    ? 'Validado em modo de simulação, enquanto a universidade '
                        'não disponibiliza a interface oficial.'
                    : 'Validado no registo académico da universidade.')
                : 'A conta foi criada sem validação porque o sistema da '
                    'universidade estava indisponível. Conclua agora a '
                    'validação para ter acesso completo.',
            style: const TextStyle(fontSize: 12, color: AppColors.cinza),
          ),
          if (validado && profile.numeroValidadoEstado != null) ...[
            const SizedBox(height: 6),
            Text(
              'Estado na universidade: ${profile.numeroValidadoEstado}',
              style: const TextStyle(fontSize: 12, color: AppColors.cinza),
            ),
          ],
          if (!validado && profile.validacaoPendente) ...[
            const SizedBox(height: 12),
            // Campus por concluir: uma conta criada com a fonte indisponivel
            // fica sem polo, e a faculdade/curso so podem ser confirmados
            // depois de saber a que campus pertencem.
            DropdownButtonFormField<String>(
              value: _polo,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Campus onde estuda',
                prefixIcon: Icon(Icons.location_city_outlined),
                isDense: true,
              ),
              items: _polos
                  .map((p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(p.rotulo, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: _aValidar ? null : _mudarPolo,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _aValidar ? null : _validarAgora,
                icon: _aValidar
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.verified_outlined),
                label: Text(_aValidar ? 'A validar...' : 'Validar agora'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String valor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cinzaBorda),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primarioClaro.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primario, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: AppColors.cinza),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}