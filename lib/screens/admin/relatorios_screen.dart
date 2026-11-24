import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../../config/app_constants.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/denuncia_provider.dart';
import '../../services/catalogo_service.dart';
import '../../utils/formatters.dart';

class RelatoriosScreen extends StatefulWidget {
  const RelatoriosScreen({super.key});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  String? _categoria;
  String? _faculdade;
  String? _status;
  DateTime? _dataInicio;
  DateTime? _dataFim;
  bool _gerandoPDF = false;

  // Lista de faculdades do catalogo publicado, para o filtro.
  final _catalogoService = CatalogoService();
  List<String> _faculdades = const [];

  @override
  void initState() {
    super.initState();
    _carregarFaculdades();
  }

  Future<void> _carregarFaculdades() async {
    final leitura = await _catalogoService.listarNomesFaculdades();
    if (!mounted) return;
    setState(() => _faculdades = leitura.itens);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().profile;
    final isSuperAdmin = profile?.isSuperAdmin ?? false;
    final faculdadeDoAdmin = profile?.faculdade;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primarioClaro.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primario,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isSuperAdmin
                          ? 'Pode gerar relatórios globais de todas as faculdades.'
                          : 'Pode gerar relatórios da sua faculdade: $faculdadeDoAdmin',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.primario,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Filtros do relatório',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primario,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _categoria,
              decoration: const InputDecoration(
                labelText: 'Categoria',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                ...AppConstants.categoriasDenuncia
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
              ],
              onChanged: (value) => setState(() => _categoria = value),
            ),
            const SizedBox(height: 16),
            if (isSuperAdmin) ...[
              DropdownButtonFormField<String>(
                value: _faculdade,
                decoration: const InputDecoration(
                  labelText: 'Faculdade',
                  prefixIcon: Icon(Icons.account_balance_outlined),
                ),
items: [
                    const DropdownMenuItem(value: null, child: Text('Todas')),
                    ..._faculdades.map(
                      (f) => DropdownMenuItem(
                        value: f,
                        child: Text(f, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                onChanged: (value) => setState(() => _faculdade = value),
              ),
              const SizedBox(height: 16),
            ],
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos')),
                ...AppConstants.statusDenuncia
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
              ],
              onChanged: (value) => setState(() => _status = value),
            ),
            const SizedBox(height: 16),
            // Período
            Row(
              children: [
                Expanded(
                  child: _buildPeriodoField(
                    label: 'Data início',
                    valor: _dataInicio,
                    onTap: () async {
                      final data = await _selecionarData();
                      if (data != null) setState(() => _dataInicio = data);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPeriodoField(
                    label: 'Data fim',
                    valor: _dataFim,
                    onTap: () async {
                      final data = await _selecionarData();
                      if (data != null) setState(() => _dataFim = data);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _gerandoPDF ? null : _gerarPDF,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: Text(_gerandoPDF ? 'A gerar...' : 'Gerar Relatório PDF'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _gerandoPDF ? null : _gerarCSV,
              icon: const Icon(Icons.table_chart_outlined),
              label: const Text('Exportar CSV'),
            ),
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Os relatórios incluem: código, categoria, faculdade, status, '
              'data e anonimato de cada denúncia registada.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.cinza,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodoField({
    required String label,
    required DateTime? valor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.date_range_outlined),
        ),
        child: Text(
          valor == null ? 'Selecionar' : Formatters.data(valor),
          style: TextStyle(
            fontSize: 14,
            color: valor == null ? AppColors.cinza : Colors.black,
          ),
        ),
      ),
    );
  }

  Future<DateTime?> _selecionarData() async {
    return showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Selecionar data',
    );
  }

  Future<List<Map<String, dynamic>>> _obterDados() async {
    final authProvider = context.read<AuthProvider>();
    final profile = authProvider.profile;
    final isSuperAdmin = profile?.isSuperAdmin ?? false;

    // Determinar faculdade (super admin pode ver tudo)
    final faculdade = isSuperAdmin ? _faculdade : profile?.faculdade;

    final provider = context.read<DenunciaProvider>();
    await provider.listarDenunciasAdmin(
      faculdade: faculdade,
      categoria: _categoria,
      status: _status,
    );

    var denuncias = provider.denunciasAdmin.toList();

    // Filtrar por período
    if (_dataInicio != null) {
      denuncias = denuncias.where((d) {
        return d.createdAt != null && !d.createdAt!.isBefore(_dataInicio!);
      }).toList();
    }
    if (_dataFim != null) {
      denuncias = denuncias.where((d) {
        return d.createdAt != null && !d.createdAt!.isAfter(_dataFim!);
      }).toList();
    }

    return denuncias
        .map((d) => {
              'Código': d.codigo,
              'Categoria': d.displayCategoria,
              'Faculdade': d.faculdade,
              'Status': d.status,
              'Data': d.createdAt != null
                  ? Formatters.dataHora(d.createdAt)
                  : '—',
              'Anónima': d.anonima ? 'Sim' : 'Não',
            })
        .toList();
  }

  Future<void> _gerarPDF() async {
    setState(() => _gerandoPDF = true);

    try {
      final dados = await _obterDados();

      if (dados.isEmpty) {
        setState(() => _gerandoPDF = false);
        _mostrarMensagem('Nenhuma denúncia encontrada com esses filtros.');
        return;
      }

      await _imprimirPDF(dados);
      setState(() => _gerandoPDF = false);
    } catch (e) {
      setState(() => _gerandoPDF = false);
      _mostrarMensagem('Erro ao gerar PDF: $e');
    }
  }

  Future<void> _imprimirPDF(List<Map<String, dynamic>> dados) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'VozUL - Relatório de Denúncias',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF1A5276),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Universidade Licungo',
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColor.fromInt(0xFF6C757D),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Gerado em: ${Formatters.dataHora(DateTime.now())}',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColor.fromInt(0xFF6C757D),
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Divider(color: PdfColor.fromInt(0xFF1A5276)),
            pw.SizedBox(height: 12),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromInt(0xFF6C757D),
            ),
          ),
        ),
        build: (context) => [
          pw.Text(
            'Total de denúncias: ${dados.length}',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Código', 'Categoria', 'Faculdade', 'Status', 'Data', 'Anónima'],
            data: dados
                .map((d) => [
                      d['Código'] as String,
                      d['Categoria'] as String,
                      d['Faculdade'] as String,
                      d['Status'] as String,
                      d['Data'] as String,
                      d['Anónima'] as String,
                    ])
                .toList(),
            headerStyle: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF1A5276),
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.topLeft,
            cellPadding: const pw.EdgeInsets.all(6),
            border: pw.TableBorder.all(
              color: PdfColor.fromInt(0xFFE0E3E7),
            ),
          ),
        ],
      ),
    );

    // Guardar e enviar para impressão
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/vozul_relatorio.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await doc.save());

    await Printing.layoutPdf(
      onLayout: (format) async => await doc.save(),
      name: 'VozUL-Relatório.pdf',
    );

    _mostrarMensagem('PDF gerado com sucesso!');
  }

  Future<void> _gerarCSV() async {
    try {
      final dados = await _obterDados();

      if (dados.isEmpty) {
        _mostrarMensagem('Nenhuma denúncia encontrada com esses filtros.');
        return;
      }

      final buffer = StringBuffer();
      buffer.writeln('Código,Categoria,Faculdade,Status,Data,Anónima');
      for (final d in dados) {
        buffer.writeln(
          '"${d['Código']}","${d['Categoria']}","${d['Faculdade']}",'
          '"${d['Status']}","${d['Data']}","${d['Anónima']}"',
        );
      }

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/vozul_relatorio.csv');
      await file.writeAsString(buffer.toString());

      // Copiar para clipboard ou enviar
      await Clipboard.setData(ClipboardData(text: buffer.toString()));

      _mostrarMensagem(
        'CSV gerado. Caminho: ${file.path}\n(ou copiado para a área de transferência)',
      );
    } catch (e) {
      _mostrarMensagem('Erro ao gerar CSV: $e');
    }
  }

  void _mostrarMensagem(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}