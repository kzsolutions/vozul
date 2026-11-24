import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/catalogo_service.dart';
import '../../services/validacao_service.dart';
import '../../utils/validators.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _validacaoService = ValidacaoService();
  final _catalogoService = CatalogoService();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _numeroController = TextEditingController();
  final _celularController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String? _faculdade;
  String? _curso;

  // Validacao do numero de estudante contra o registo academico
  List<Polo> _polos = const [];
  String? _poloSelecionado;
  ResultadoValidacao? _validacao;
  bool _aValidar = false;

  // Catalogo oficial do campus escolhido. As listas vem da base de dados:
  // a faculdade e o curso tem de existir no catalogo do campus, e nao numa
  // lista guardada no codigo do dispositivo.
  List<Faculdade> _faculdades = const [];
  List<Curso> _cursos = const [];
  bool _aCarregarFaculdades = false;
  bool _aCarregarCursos = false;
  String? _erroCatalogo;
  String? _erroCursos;

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  /// `true` quando a universidade ja devolveu faculdade e curso oficiais.
  /// Nesse caso os campos mostram o que a universidade registou e nao podem
  /// ser alterados a mao: mudar a mano seria afirmar algo que a fonte nao
  /// confirmou.
  bool get _validadoPelaUniversidade =>
      _validacao?.confirmado == true &&
      _validacao?.faculdade != null &&
      _validacao?.curso != null;

  @override
  void initState() {
    super.initState();
    _carregarPolos();
    // Ao mudar o numero, a validacao anterior deixa de servir.
    _numeroController.addListener(_invalidarValidacao);
  }

  Future<void> _carregarPolos() async {
    final leitura = await _catalogoService.listarPolos();
    if (!mounted) return;

    setState(() {
      _polos = leitura.itens;
      _erroCatalogo = leitura.erro;
      // Campus sede (Quelimane) em primeiro lugar, por ser o mais frequente.
      _poloSelecionado ??= leitura.itens.isNotEmpty ? leitura.itens.first.id : null;
    });

    if (_poloSelecionado != null) {
      await _carregarFaculdades(_poloSelecionado!);
    }
  }

  Future<void> _carregarFaculdades(String poloId) async {
    setState(() {
      _aCarregarFaculdades = true;
      _erroCatalogo = null;
    });

    final leitura = await _catalogoService.listarFaculdades(poloId);
    if (!mounted) return;

    setState(() {
      _faculdades = leitura.itens;
      _aCarregarFaculdades = false;
      _erroCatalogo = leitura.erro;
    });
  }

  Future<void> _carregarCursos(String faculdadeId) async {
    setState(() {
      _aCarregarCursos = true;
      _erroCursos = null;
      _cursos = const [];
    });

    final leitura = await _catalogoService.listarCursos(faculdadeId);
    if (!mounted) return;

    setState(() {
      _cursos = leitura.itens;
      _aCarregarCursos = false;
      _erroCursos = leitura.erro;
    });
  }

  /// Trocar de campus invalida tudo o que dependia do campus anterior.
  void _mudarPolo(String? poloId) {
    setState(() {
      _poloSelecionado = poloId;
      _validacao = null;
      _faculdade = null;
      _curso = null;
      _faculdades = const [];
      _cursos = const [];
    });

    if (poloId != null) _carregarFaculdades(poloId);
  }

  void _invalidarValidacao() {
    // Evita mostrar "validado" para um numero que o utilizador ja alterou.
    if (_validacao != null && _validacao!.confirmado) {
      setState(() => _validacao = null);
    }
  }

  /// Identificador da faculdade escolhida no catálogo, para carregar os cursos.
  String? _idFaculdade(String? nome) {
    for (final f in _faculdades) {
      if (f.nome == nome) return f.id;
    }
    return null;
  }

  /// Faixa de aviso com acção de nova tentativa.
  Widget _aviso(
    String mensagem, {
    required Color cor,
    required IconData icone,
    VoidCallback? onTentar,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cor.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: cor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensagem,
              style: TextStyle(fontSize: 13, color: cor),
            ),
          ),
          if (onTentar != null)
            TextButton(
              onPressed: onTentar,
              child: const Text('Tentar de novo'),
            ),
        ],
      ),
    );
  }

  Widget _carregando({required String texto}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            texto,
            style: const TextStyle(fontSize: 13, color: AppColors.cinza),
          ),
        ],
      ),
    );
  }

  Future<void> _validarNumero() async {
    final numero = _numeroController.text.trim();
    if (numero.isEmpty) {
      setState(() => _validacao = const ResultadoValidacao(
        valido: false,
        mensagem: 'Introduza o número de estudante.',
      ));
      return;
    }

    setState(() {
      _aValidar = true;
      _validacao = null;
    });

    final resultado = await _validacaoService.validar(
      numero: numero,
      polo: _poloSelecionado,
    );

    if (!mounted) return;
    setState(() {
      _validacao = resultado;
      _aValidar = false;

      // A universidade e a fonte da verdade: se devolveu a faculdade/curso,
      // o formulario passa a mostrar o que a universidade registou.
      if (resultado.confirmado) {
        if (resultado.faculdade != null) _faculdade = resultado.faculdade;
        if (resultado.curso != null) _curso = resultado.curso;
      }
    });
  }

  @override
  void dispose() {
    _numeroController.removeListener(_invalidarValidacao);
    _nomeController.dispose();
    _emailController.dispose();
    _numeroController.dispose();
    _celularController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _registar() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    final authProvider = context.read<AuthProvider>();

    // Revalida no momento do registo: entre a validacao visual e o envio o
    // numero pode ter sido alterado, e a fonte academica pode ter mudado.
    setState(() => _aValidar = true);
    final validacao = await _validacaoService.validar(
      numero: _numeroController.text.trim(),
      polo: _poloSelecionado,
    );
    if (!mounted) return;
    setState(() {
      _validacao = validacao;
      _aValidar = false;
    });

    // Recusa clara da universidade impede a criacao da conta.
    // Indisponibilidade da fonte (pendente) nao impede: culpar o aluno por
    // uma falha da universidade seria errado. O perfil fica sem validacao
    // e o registo e retomado quando a fonte responder.
    if (validacao.valido == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validacao.mensagem),
          backgroundColor: AppColors.vermelho,
        ),
      );
      return;
    }

    final sucesso = await authProvider.registarEstudante(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      numeroEstudante: _numeroController.text.trim(),
      celular: _celularController.text.trim(),
      nomeCompleto: _nomeController.text.trim(),
      faculdade: _faculdade,
      curso: _curso,
    );

    if (!mounted) return;

    if (sucesso) {
      if (validacao.pendente) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Conta criada. O número de estudante ficou por validar '
              'porque a universidade não respondeu — pode usar a app e '
              'validar mais tarde.',
            ),
            backgroundColor: AppColors.amarelo,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conta criada com sucesso. Faça login para continuar.'),
            backgroundColor: AppColors.verde,
          ),
        );
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Erro ao registar'),
          backgroundColor: AppColors.vermelho,
        ),
      );
    }
  }

  /// Mostra o resultado da validacao academica com linguagem clara.
  Widget _cartaoValidacao(ResultadoValidacao v) {
    final (IconData icone, Color cor, Color fundo) = switch (v.valido) {
      true => (Icons.check_circle, AppColors.verde, AppColors.verdeClaro),
      false => (Icons.cancel, AppColors.vermelho, AppColors.vermelhoClaro),
      null => (Icons.cloud_off, AppColors.amarelo, AppColors.amareloClaro),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cor.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: cor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v.mensagem,
                  style: TextStyle(
                    fontSize: 13,
                    color: cor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (v.confirmado && v.faculdade != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${v.faculdade}'
                    '${v.curso == null ? '' : ' — ${v.curso}'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.cinza,
                    ),
                  ),
                ],
                // Deixa claro, no dispositivo, que a origem foi simulacao.
                if (v.origem == 'mock') ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Modo de simulação: o número não foi confirmado no '
                    'sistema da universidade.',
                    style: TextStyle(fontSize: 11, color: AppColors.cinza),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registo de Estudante'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.verdeClaro,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.verde.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: AppColors.verde, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Os seus dados são usados apenas para autenticação. '
                          'Pode denunciar anonimamente se desejar.',
                          style: TextStyle(fontSize: 13, color: AppColors.verde),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nomeController,
                  validator: (v) => Validators.required(v, 'Nome'),
                  decoration: const InputDecoration(
                    labelText: 'Nome completo',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _poloSelecionado,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Campus / delegação',
                    prefixIcon: const Icon(Icons.location_city_outlined),
                    helperText: 'A lista de faculdades e cursos depende do campus',
                    helperMaxLines: 2,
                    suffixIcon: _erroCatalogo == null || _aCarregarFaculdades
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Tentar novamente',
                            onPressed: () {
                              final polo = _poloSelecionado;
                              if (polo != null) _carregarFaculdades(polo);
                            },
                          ),
                  ),
                  items: _polos
                      .map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(p.rotulo, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: _aValidar ? null : _mudarPolo,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _numeroController,
                  keyboardType: TextInputType.number,
                  validator: Validators.numeroEstudante,
                  decoration: InputDecoration(
                    labelText: 'Número de estudante',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    suffixIcon: _aValidar
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.verified_user_outlined),
                            tooltip: 'Validar na universidade',
                            onPressed: _validarNumero,
                          ),
                  ),
                ),
                _validacao == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: _cartaoValidacao(_validacao!),
                      ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _celularController,
                  keyboardType: TextInputType.phone,
                  validator: Validators.celular,
                  decoration: const InputDecoration(
                    labelText: 'Número de celular',
                    prefixIcon: Icon(Icons.phone_android),
                  ),
                ),
                const SizedBox(height: 16),
                if (_erroCatalogo != null)
                  _aviso(
                    _erroCatalogo!,
                    cor: AppColors.vermelho,
                    icone: Icons.cloud_off,
                    onTentar: () {
                      final polo = _poloSelecionado;
                      if (polo == null) {
                        _carregarPolos();
                      } else {
                        _carregarFaculdades(polo);
                      }
                    },
                  )
                else if (_aCarregarFaculdades)
                  _carregando(texto: 'A carregar faculdades do campus…')
                else if (_faculdades.isEmpty && _poloSelecionado != null)
                  _aviso(
                    'Não há faculdades publicadas para este campus. Contacte a '
                    'secretaria da universidade.',
                    cor: AppColors.amarelo,
                    icone: Icons.info_outline,
                  )
                else
                  DropdownButtonFormField<String>(
                    value: _faculdade,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Faculdade',
                      prefixIcon: const Icon(Icons.account_balance_outlined),
                      suffixIcon: _validadoPelaUniversidade
                          ? const Icon(Icons.lock_outline)
                          : null,
                    ),
                    items: _faculdades
                        .map((f) => DropdownMenuItem(
                              value: f.nome,
                              child: Text(f.nome, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: _validadoPelaUniversidade
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
                if (_erroCursos != null)
                  _aviso(
                    _erroCursos!,
                    cor: AppColors.vermelho,
                    icone: Icons.cloud_off,
                    onTentar: () {
                      final id = _idFaculdade(_faculdade);
                      if (id != null) _carregarCursos(id);
                    },
                  )
                else if (_aCarregarCursos)
                  _carregando(texto: 'A carregar cursos…')
                else
                  DropdownButtonFormField<String>(
                    value: _curso,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Curso',
                      prefixIcon: const Icon(Icons.school_outlined),
                      suffixIcon: _validadoPelaUniversidade
                          ? const Icon(Icons.lock_outline)
                          : null,
                    ),
                    items: _cursos
                        .map((c) => DropdownMenuItem(
                              value: c.nome,
                              child: Text(c.nome, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged:
                        _validadoPelaUniversidade || _faculdade == null
                            ? null
                            : (value) => setState(() => _curso = value),
                    hint: Text(
                      _faculdade == null
                          ? 'Selecione a faculdade primeiro'
                          : _cursos.isEmpty
                              ? 'Esta faculdade ainda não tem cursos publicados'
                              : 'Selecione o curso',
                      style: const TextStyle(fontSize: 14, color: AppColors.cinza),
                    ),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: Validators.password,
                  decoration: InputDecoration(
                    labelText: 'Palavra-passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  validator: (v) =>
                      Validators.confirmPassword(v, _passwordController.text),
                  decoration: InputDecoration(
                    labelText: 'Confirmar palavra-passe',
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(
                          () => _obscureConfirm = !_obscureConfirm,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: (authProvider.isLoading || _aValidar)
                      ? null
                      : _registar,
                  child: authProvider.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Criar conta'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Já tenho conta — Entrar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}