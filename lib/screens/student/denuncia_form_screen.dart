import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../config/app_constants.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/denuncia_provider.dart';
import '../../services/catalogo_service.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import 'denuncia_sucesso_screen.dart';

class DenunciaFormScreen extends StatefulWidget {
  final String? categoriaPreSelecionada;

  const DenunciaFormScreen({super.key, this.categoriaPreSelecionada});

  @override
  State<DenunciaFormScreen> createState() => _DenunciaFormScreenState();
}

class _DenunciaFormScreenState extends State<DenunciaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _catalogoService = CatalogoService();

  // Campos
  String? _categoria;
  final _categoriaOutraController = TextEditingController();
  String? _polo;
  String? _faculdade;
  String? _curso;
  String? _denunciadoTipo;
  final _denunciadoNomeController = TextEditingController();
  final _denunciadoNumeroController = TextEditingController();
  final _denunciadoCelularController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _emailNotificacaoController = TextEditingController();
  String? _local;
  final _localOutroController = TextEditingController();
  DateTime? _dataOcorrido;
  bool _anonima = true;

  // Uploads
  final List<File> _evidencias = [];
  bool _enviando = false;

  // Catalogo por campus: a faculdade e o curso tem de existir na lista
  // publicada para o campus escolhido.
  List<Polo> _polos = const [];
  List<Faculdade> _faculdades = const [];
  List<Curso> _cursos = const [];
  bool _aCarregarCatalogo = false;
  String? _erroCatalogo;

  // Locais mapeados para o campus escolhido. Vazio = a universidade ainda
  // nao definiu locais para este campus (Beira) e o estudante escreve o
  // local; nesse caso nao ha opcoes predefinidas para escolher.
  List<String> _locais = const [];
  bool _aCarregarLocais = false;

  @override
  void initState() {
    super.initState();
    _categoria = widget.categoriaPreSelecionada;
    _carregarCatalogoInicial();
  }

  /// Campus e catálogo inicial.
  ///
  /// O campus por omissão é o do perfil do estudante; sem perfil (ou sem
  /// campus definido) usa-se o campus sede. A denúncia é sobre um lugar
  /// concreto, por isso a faculdade tem de ser escolhida a partir da lista
  /// daquele campus.
  Future<void> _carregarCatalogoInicial() async {
    final leituraPolos = await _catalogoService.listarPolos();
    if (!mounted) return;

    final campusPreferido = context.read<AuthProvider>().profile?.poloId;

    setState(() {
      _polos = leituraPolos.itens;
      _erroCatalogo = leituraPolos.erro;
    });

    if (leituraPolos.itens.isEmpty) {
      if (leituraPolos.erro != null) setState(() => _erroCatalogo = leituraPolos.erro);
      return;
    }

    final inicial = leituraPolos.itens.firstWhere(
      (p) => p.id == campusPreferido,
      orElse: () => leituraPolos.itens.first,
    );

    setState(() => _polo = inicial.id);
    await _carregarFaculdades(inicial.id);
    await _carregarLocais(inicial.id);
  }

  Future<void> _carregarFaculdades(String poloId) async {
    setState(() {
      _aCarregarCatalogo = true;
      _erroCatalogo = null;
    });

    final leitura = await _catalogoService.listarFaculdades(poloId);
    if (!mounted) return;

    setState(() {
      _faculdades = leitura.itens;
      _aCarregarCatalogo = false;
      _erroCatalogo = leitura.erro;
    });
  }

  Future<void> _carregarCursos(String faculdadeId) async {
    setState(() {
      _aCarregarCatalogo = true;
      _erroCatalogo = null;
      _cursos = const [];
    });

    final leitura = await _catalogoService.listarCursos(faculdadeId);
    if (!mounted) return;

    setState(() {
      _cursos = leitura.itens;
      _aCarregarCatalogo = false;
      _erroCatalogo = leitura.erro;
    });
  }

  /// Locais de ocorrência do campus, que determinam como o campo é apresentado.
  ///
  /// Ao trocar de campus o local escolhido deixa de fazer sentido (os locais
  /// são de um lugar concreto), por isso a escolha anterior é limpa antes de
  /// carregar a lista do campus novo.
  Future<void> _carregarLocais(String poloId) async {
    setState(() {
      _aCarregarLocais = true;
      _local = null;
      _localOutroController.clear();
    });

    final leitura = await _catalogoService.listarLocais(poloId);
    if (!mounted) return;

    setState(() {
      _locais = leitura.itens;
      _aCarregarLocais = false;
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
      _locais = const [];
    });
    if (poloId != null) {
      _carregarFaculdades(poloId);
      _carregarLocais(poloId);
    }
  }

  @override
  void dispose() {
    _denunciadoNomeController.dispose();
    _denunciadoNumeroController.dispose();
    _denunciadoCelularController.dispose();
    _descricaoController.dispose();
    _emailNotificacaoController.dispose();
    _categoriaOutraController.dispose();
    _localOutroController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final hoje = DateTime.now();
    final selecionada = await showDatePicker(
      context: context,
      initialDate: _dataOcorrido ?? hoje,
      firstDate: DateTime(2000),
      lastDate: hoje,
      helpText: 'Data do ocorrido',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );

    if (selecionada != null) {
      setState(() => _dataOcorrido = selecionada);
    }
  }

  Future<void> _adicionarEvidencia() async {
    final tipos = ['Imagens', 'PDFs', 'Áudios', 'Vídeos'];
    final escolha = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Adicionar evidência',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            ...tipos.map(
              (tipo) => ListTile(
                leading: Icon(_iconeTipo(tipo)),
                title: Text(tipo),
                onTap: () => Navigator.pop(context, tipo),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (escolha == null) return;

    await _selecionarArquivo(escolha);
  }

  IconData _iconeTipo(String tipo) {
    switch (tipo) {
      case 'Imagens':
        return Icons.image_outlined;
      case 'PDFs':
        return Icons.picture_as_pdf_outlined;
      case 'Áudios':
        return Icons.audiotrack_outlined;
      case 'Vídeos':
        return Icons.videocam_outlined;
      default:
        return Icons.attach_file;
    }
  }

  Future<void> _selecionarArquivo(String tipo) async {
    if (_evidencias.length >= AppConstants.maxFiles) {
      _mostrarErro('Máximo de ${AppConstants.maxFiles} ficheiros.');
      return;
    }

    try {
      if (tipo == 'Imagens' || tipo == 'Vídeos') {
        final picker = ImagePicker();
        final imagens = await picker.pickMultipleMedia();
        if (imagens.isEmpty) return;

        for (final imagem in imagens) {
          if (_evidencias.length >= AppConstants.maxFiles) break;
          final file = File(imagem.path);
          if (await _validarArquivo(file)) {
            setState(() => _evidencias.add(file));
          }
        }
      } else {
        final result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: tipo == 'PDFs' ? ['pdf'] : ['mp3', 'wav'],
        );

        if (result.isEmpty) return;

        for (final arquivo in result) {
          if (arquivo.path == null) continue;
          if (_evidencias.length >= AppConstants.maxFiles) break;
          final file = File(arquivo.path!);
          if (await _validarArquivo(file)) {
            setState(() => _evidencias.add(file));
          }
        }
      }
    } catch (e) {
      _mostrarErro('Erro ao selecionar ficheiro: $e');
    }
  }

  Future<bool> _validarArquivo(File file) async {
    final size = await file.length();
    final maxSize = AppConstants.maxFileSizeMB * 1024 * 1024;

    if (size > maxSize) {
      _mostrarErro(
        'Ficheiro excede ${AppConstants.maxFileSizeMB}MB: ${file.path.split('/').last}',
      );
      return false;
    }

    return true;
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: AppColors.vermelho,
      ),
    );
  }

  /// Local que segue com a denúncia.
  ///
  /// Com locais mapeados para o campus, vale a escolha da lista — e, se a
  /// escolha for "Outro", a descrição escrita. Sem locais mapeados o campo
  /// é texto livre e vale o que o estudante escreveu.
  String? get _localOcorrido {
    if (_locais.isEmpty || _local == 'Outro') {
      final texto = _localOutroController.text.trim();
      return texto.isEmpty ? null : texto;
    }
    return _local;
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    // Validações condicionais
    if (_categoria == 'Outro' &&
        _categoriaOutraController.text.trim().isEmpty) {
      _mostrarErro('Descreva o tipo de denúncia');
      return;
    }

    if (_denunciadoTipo != null) {
      if (_denunciadoTipo == 'Docente' &&
          _denunciadoNomeController.text.trim().isEmpty) {
        _mostrarErro('Indique o nome do docente');
        return;
      }
      if (_denunciadoTipo == 'Estudante' &&
          _denunciadoNomeController.text.trim().isEmpty) {
        _mostrarErro('Indique o nome do estudante');
        return;
      }
      if (_denunciadoTipo == 'Funcionário' &&
          _denunciadoNomeController.text.trim().isEmpty) {
        _mostrarErro('Indique o nome do funcionário');
        return;
      }
    }

    if (_local == 'Outro' &&
        _localOutroController.text.trim().isEmpty) {
      _mostrarErro('Descreva o local do ocorrido');
      return;
    }

    // A faculdade vem do catalogo publicado. Sem ela nao ha como registar a
    // ocorrencia: e esse par que situa a denuncia na universidade.
    if (_faculdade == null || _faculdade!.isEmpty) {
      _mostrarErro(_erroCatalogo != null
          ? 'Não foi possível carregar as faculdades. Verifique a ligação e tente novamente.'
          : 'Selecione a faculdade onde ocorreu');
      return;
    }

    setState(() => _enviando = true);

    final denunciaProvider = context.read<DenunciaProvider>();
    final authProvider = context.read<AuthProvider>();

    final estudanteId = _anonima ? null : authProvider.profile?.id;

    final denuncia = await denunciaProvider.criarDenuncia(
      categoria: _categoria!,
      categoriaCustom: _categoria == 'Outro'
          ? _categoriaOutraController.text.trim()
          : null,
      descricao: _descricaoController.text.trim(),
      denunciadoTipo: _denunciadoTipo?.toLowerCase(),
      denunciadoNome: _denunciadoTipo == 'Docente' ||
              _denunciadoTipo == 'Estudante' ||
              _denunciadoTipo == 'Funcionário'
          ? _denunciadoNomeController.text.trim()
          : null,
      denunciadoNumero:
          _denunciadoNumeroController.text.trim().isEmpty
              ? null
              : _denunciadoNumeroController.text.trim(),
      denunciadoCelular:
          _denunciadoCelularController.text.trim().isEmpty
              ? null
              : _denunciadoCelularController.text.trim(),
      faculdade: _faculdade!,
      curso: _curso,
      poloId: _polo,
      localOcorrido: _localOcorrido,
      dataOcorrido: _dataOcorrido,
      anonima: _anonima,
      estudanteId: estudanteId,
      emailNotificacao: _emailNotificacaoController.text.trim().isEmpty
          ? null
          : _emailNotificacaoController.text.trim(),
      evidencias: _evidencias.isEmpty ? null : _evidencias,
    );

    setState(() => _enviando = false);

    if (!mounted) return;

    if (denuncia != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DenunciaSucessoScreen(denuncia: denuncia),
        ),
      );
    } else {
      _mostrarErro(denunciaProvider.error ?? 'Erro ao enviar denúncia');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fazer Denúncia'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _enviando
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primario),
                  SizedBox(height: 16),
                  Text(
                    'A enviar a sua denúncia...',
                    style: TextStyle(color: AppColors.cinza),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildAnonimatoToggle(),
                      const SizedBox(height: 20),
                      _buildCategoriaSection(),
                      const SizedBox(height: 20),
                      _buildFaculdadeSection(),
                      const SizedBox(height: 20),
                      _buildDenunciadoSection(),
                      const SizedBox(height: 20),
                      _buildDescricaoSection(),
                      const SizedBox(height: 20),
                      if (_anonima) ...[
                        _buildEmailNotificacaoSection(),
                        const SizedBox(height: 20),
                      ],
                      _buildOcorridoSection(),
                      const SizedBox(height: 24),
                      _buildEvidenciasSection(),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _enviar,
                        icon: const Icon(Icons.send_outlined),
                        label: const Text('Enviar Denúncia'),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Ao enviar, confirma que esta denúncia é verdadeira e feita de boa-fé. Denúncias falsas podem ter consequências.',
                        style: TextStyle(fontSize: 12, color: AppColors.cinza),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildAnonimatoToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _anonima ? AppColors.verde : AppColors.primario,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _anonima ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: _anonima ? AppColors.verde : AppColors.primario,
              ),
              const SizedBox(width: 10),
              const Text(
                'Modo da denúncia',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ModoCard(
                  titulo: 'Anónima',
                  descricao: 'Sem revelar identidade',
                  icone: Icons.shield_outlined,
                  selecionado: _anonima,
                  cor: AppColors.verde,
                  onTap: () => setState(() => _anonima = true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ModoCard(
                  titulo: 'Identificada',
                  descricao: 'Visível à Comissão',
                  icone: Icons.badge_outlined,
                  selecionado: !_anonima,
                  cor: AppColors.primario,
                  onTap: () => setState(() => _anonima = false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriaSection() {
    return _SectionCard(
      titulo: 'Tipo de denúncia',
      icon: Icons.category_outlined,
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _categoria,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Selecione o tipo',
              prefixIcon: Icon(Icons.report_problem_outlined),
            ),
            items: AppConstants.categoriasDenuncia
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _categoria = value;
                if (value != 'Outro') {
                  _categoriaOutraController.clear();
                }
              });
            },
          ),
          if (_categoria == 'Outro') ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _categoriaOutraController,
              decoration: const InputDecoration(
                labelText: 'Descreva o tipo',
                hintText: 'Ex: Falsificação de documentos...',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
              maxLines: 2,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFaculdadeSection() {
    return _SectionCard(
      titulo: 'Campus, Faculdade e Curso',
      icon: Icons.account_balance_outlined,
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _polo,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Campus / delegação',
              prefixIcon: Icon(Icons.location_city_outlined),
            ),
            items: _polos
                .map((p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(p.rotulo, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: _aCarregarCatalogo ? null : _mudarPolo,
          ),
          const SizedBox(height: 12),
          if (_erroCatalogo != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _erroCatalogo!,
                style: const TextStyle(fontSize: 12, color: AppColors.vermelho),
              ),
            )
          else if (_aCarregarCatalogo)
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            DropdownButtonFormField<String>(
              value: _faculdade,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Faculdade',
                prefixIcon: const Icon(Icons.search_outlined),
                suffixIcon: _faculdade != null
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setState(() {
                            _faculdade = null;
                            _curso = null;
                            _cursos = const [];
                          });
                        },
                      )
                    : null,
              ),
              items: _faculdades
                  .map((f) => DropdownMenuItem(
                        value: f.nome,
                        child: Text(f.nome, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _faculdade = value;
                  _curso = null;
                });
                final id = _idFaculdade(value);
                if (id != null) _carregarCursos(id);
              },
            ),
          const SizedBox(height: 12),
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
            onChanged: _faculdade == null ? null : (value) => setState(() => _curso = value),
          ),
        ],
      ),
    );
  }

  Widget _buildDenunciadoSection() {
    return _SectionCard(
      titulo: 'Quem é o denunciado?',
      icon: Icons.person_pin_outlined,
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _denunciadoTipo,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Categoria do denunciado',
              prefixIcon: Icon(Icons.person_outline),
            ),
            items: AppConstants.tiposDenunciado
                .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _denunciadoTipo = value;
                _denunciadoNomeController.clear();
                _denunciadoNumeroController.clear();
                _denunciadoCelularController.clear();
              });
            },
          ),
          if (_denunciadoTipo != null) ...[
            const SizedBox(height: 12),
            if (_denunciadoTipo == 'Docente') ...[
              TextFormField(
                controller: _denunciadoNomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do docente',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _denunciadoNumeroController,
                decoration: const InputDecoration(
                  labelText: 'Número de funcionário',
                  prefixIcon: Icon(Icons.numbers_outlined),
                ),
              ),
            ],
            if (_denunciadoTipo == 'Estudante') ...[
              TextFormField(
                controller: _denunciadoNomeController,
                validator: (v) => Validators.required(v, 'Nome do estudante'),
                decoration: const InputDecoration(
                  labelText: 'Nome do estudante',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _denunciadoNumeroController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Número de estudante (opcional)',
                  prefixIcon: Icon(Icons.numbers_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _denunciadoCelularController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Celular do estudante (opcional)',
                  prefixIcon: Icon(Icons.phone_android),
                ),
              ),
            ],
            if (_denunciadoTipo == 'Funcionário') ...[
              TextFormField(
                controller: _denunciadoNomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do funcionário',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _denunciadoNumeroController,
                decoration: const InputDecoration(
                  labelText: 'Número de funcionário',
                  prefixIcon: Icon(Icons.numbers_outlined),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDescricaoSection() {
    return _SectionCard(
      titulo: 'Descrição do ocorrido',
      icon: Icons.description_outlined,
      child: TextFormField(
        controller: _descricaoController,
        maxLines: 6,
        validator: (v) => Validators.required(v, 'Descrição'),
        decoration: const InputDecoration(
          hintText: 'Descreva detalhadamente o que aconteceu...',
          alignLabelWithHint: true,
        ),
      ),
    );
  }

  Widget _buildEmailNotificacaoSection() {
    return _SectionCard(
      titulo: 'Notificações por email (opcional)',
      icon: Icons.notifications_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _emailNotificacaoController,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              return Validators.email(v);
            },
            decoration: const InputDecoration(
              labelText: 'Email para receber atualizações',
              hintText: 'exemplo@email.com',
              prefixIcon: Icon(Icons.alternate_email),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Será notificado por email quando o estado da denúncia mudar ou a Comissão responder. Em modo anónimo, este email não fica associado à sua identidade.',
            style: TextStyle(fontSize: 12, color: AppColors.cinza),
          ),
        ],
      ),
    );
  }

  Widget _buildOcorridoSection() {
    return _SectionCard(
      titulo: 'Data e local do ocorrido',
      icon: Icons.calendar_month_outlined,
      child: Column(
        children: [
          InkWell(
            onTap: _selecionarData,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Data do ocorrido',
                prefixIcon: Icon(Icons.event_outlined),
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
              child: Text(
                _dataOcorrido == null
                    ? 'Selecione a data'
                    : Formatters.dataLonga(_dataOcorrido),
                style: TextStyle(
                  fontSize: 15,
                  color: _dataOcorrido == null
                      ? AppColors.cinza
                      : Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_aCarregarLocais)
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_locais.isNotEmpty)
            DropdownButtonFormField<String>(
              value: _local,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Local do ocorrido',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              items: [..._locais, 'Outro']
                  .map((l) => DropdownMenuItem(
                        value: l,
                        child: Text(l, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _local = value;
                  if (value != 'Outro') _localOutroController.clear();
                });
              },
            )
          else
            // Campus sem locais publicados (delegação da Beira): não há
            // opções para sugerir, por isso o estudante descreve o local.
            TextFormField(
              controller: _localOutroController,
              decoration: const InputDecoration(
                labelText: 'Local do ocorrido',
                hintText: 'Descreva o local, ex.: Campus X — Bloco Y',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
          if (_locais.isNotEmpty && _local == 'Outro') ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _localOutroController,
              decoration: const InputDecoration(
                labelText: 'Descreva o local',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEvidenciasSection() {
    return _SectionCard(
      titulo: 'Evidências (provas)',
      icon: Icons.attach_file,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_evidencias.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.amareloClaro,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.amarelo, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sem provas anexadas. A Comissão será informada que não há evidências.',
                      style: TextStyle(fontSize: 12, color: AppColors.amarelo),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _evidencias.asMap().entries.map((entry) {
              final index = entry.key;
              final file = entry.value;
              return Stack(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cinzaBorda),
                      color: AppColors.cinzaClaro,
                    ),
                    child: _previewArquivo(file),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _evidencias.removeAt(index));
                      },
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: AppColors.vermelho,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          if (_evidencias.length < AppConstants.maxFiles)
            OutlinedButton.icon(
              onPressed: _adicionarEvidencia,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Adicionar evidência'),
            ),
          const SizedBox(height: 8),
          Text(
            'Imagens, PDFs, áudios e vídeos. Máx. ${AppConstants.maxFiles} ficheiros de ${AppConstants.maxFileSizeMB}MB.',
            style: const TextStyle(fontSize: 11, color: AppColors.cinza),
          ),
        ],
      ),
    );
  }

  Widget _previewArquivo(File file) {
    final extensao = file.path.split('.').last.toLowerCase();
    final nome = file.path.split('/').last;

    if (['jpg', 'jpeg', 'png'].contains(extensao)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(file, fit: BoxFit.cover),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          extensao == 'pdf'
              ? Icons.picture_as_pdf_outlined
              : ['mp3', 'wav'].contains(extensao)
                  ? Icons.audiotrack_outlined
                  : Icons.videocam_outlined,
          color: AppColors.primario,
          size: 24,
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            nome,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9, color: AppColors.cinza),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String titulo;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.titulo,
    required this.icon,
    required this.child,
  });

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
          Row(
            children: [
              Icon(icon, color: AppColors.primario, size: 20),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primario,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ModoCard extends StatelessWidget {
  final String titulo;
  final String descricao;
  final IconData icone;
  final bool selecionado;
  final Color cor;
  final VoidCallback onTap;

  const _ModoCard({
    required this.titulo,
    required this.descricao,
    required this.icone,
    required this.selecionado,
    required this.cor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selecionado ? cor.withValues(alpha: 0.08) : AppColors.cinzaClaro,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selecionado ? cor : AppColors.cinzaBorda,
            width: selecionado ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icone, color: cor, size: 28),
            const SizedBox(height: 8),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selecionado ? cor : AppColors.cinza,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              descricao,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppColors.cinza),
            ),
          ],
        ),
      ),
    );
  }
}