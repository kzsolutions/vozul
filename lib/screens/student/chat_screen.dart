import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/denuncia.dart';
import '../../models/mensagem.dart';
import '../../providers/chat_provider.dart';
import '../../utils/formatters.dart';

class ChatScreen extends StatefulWidget {
  final Denuncia denuncia;
  final bool isAdminView;

  const ChatScreen({
    super.key,
    required this.denuncia,
    this.isAdminView = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _aEnviar = false;
  bool _carregandoConversa = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _iniciarConversa();
    });
  }

  /// Em denúncias anónimas o estudante acompanha pelo código: primeiro fica
  /// associado à conversa e só depois carrega o histórico — caso contrário a
  /// RLS devolve vazio e a primeira mensagem é recusada.
  Future<void> _iniciarConversa() async {
    final provider = context.read<ChatProvider>();

    if (!widget.isAdminView) {
      await provider.registrarParticipacao(widget.denuncia.codigo);
    }
    if (!mounted) return;

    await provider.carregarMensagens(widget.denuncia.id);
    if (!mounted) return;

    setState(() => _carregandoConversa = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _enviar() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty || _aEnviar) return;

    final provider = context.read<ChatProvider>();
    final remetente = widget.isAdminView ? 'comissao' : 'estudante';

    setState(() => _aEnviar = true);
    provider.limparErro();

    final ok = await provider.enviarMensagem(
      denunciaId: widget.denuncia.id,
      remetente: remetente,
      conteudo: texto,
    );

    if (!mounted) return;
    // Só limpa o texto depois de gravar: caso contrário a mensagem desaparece
    // sem aviso quando o envio falha.
    if (ok) {
      _controller.clear();
      _scrollParaBaixo();
    }
    setState(() => _aEnviar = false);
  }

  void _scrollParaBaixo() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();

    // Marcar mensagens como lidas
    final remetente = widget.isAdminView ? 'comissao' : 'estudante';
    Future.microtask(() {
      if (provider.mensagens.isNotEmpty) {
        provider.marcarComoLidas(widget.denuncia.id, remetente);
      }
    });

    final mensagens = provider.mensagens;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              widget.isAdminView
                  ? (widget.denuncia.anonima
                      ? 'Denunciante Anónimo'
                      : 'Estudante')
                  : 'Comissão de Ética',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              widget.denuncia.codigo,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          if (widget.isAdminView)
            Padding(
              padding: const EdgeInsets.all(12),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_vert),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Cabeçalho da denúncia
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.cinzaClaro,
              border: Border(
                bottom: BorderSide(color: AppColors.cinzaBorda),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.report_problem_outlined,
                  size: 18,
                  color: AppColors.primario,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.denuncia.displayCategoria} • ${widget.denuncia.faculdade}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primario,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Erro visível (RLS, sessão, rede) — antes existed apenas em silêncio
          if (provider.error != null) _buildAvisoErro(provider.error!),
          // Mensagens
          Expanded(
            child: _carregandoConversa
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primario),
                  )
                : mensagens.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 56,
                              color: AppColors.cinza,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Sem mensagens ainda',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.cinza,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Envie uma mensagem para iniciar a conversa',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.cinza,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: mensagens.length,
                        itemBuilder: (context, index) {
                          final msg = mensagens[index];
                          return _buildBubble(msg);
                        },
                      ),
          ),
          // Input
          Container(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppColors.cinzaBorda),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Escreva uma mensagem...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                      filled: true,
                      fillColor: AppColors.cinzaClaro,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  onPressed: _aEnviar ? null : _enviar,
                  backgroundColor: AppColors.primario,
                  foregroundColor: Colors.white,
                  child: _aEnviar
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Faixa de erro visível no chat
  Widget _buildAvisoErro(String mensagem) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.vermelho.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.vermelho.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.vermelho),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensagem,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.vermelho,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: AppColors.vermelho),
            onPressed: () => context.read<ChatProvider>().limparErro(),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(Mensagem msg) {
    final souEu = msg.isEstudante != widget.isAdminView;

    return Align(
      alignment: souEu ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: souEu ? AppColors.primario : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(souEu ? 16 : 4),
            bottomRight: Radius.circular(souEu ? 4 : 16),
          ),
          border: souEu ? null : Border.all(color: AppColors.cinzaBorda),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              msg.conteudo,
              style: TextStyle(
                fontSize: 14,
                color: souEu ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              Formatters.dataHora(msg.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: souEu ? Colors.white70 : AppColors.cinza,
              ),
            ),
          ],
        ),
      ),
    );
  }
}