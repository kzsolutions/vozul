import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/denuncia_com_mensagem.dart';
import '../../providers/auth_provider.dart';
import '../../providers/denuncia_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import 'chat_screen.dart';

class ChatListStudentScreen extends StatefulWidget {
  const ChatListStudentScreen({super.key});

  @override
  State<ChatListStudentScreen> createState() => _ChatListStudentScreenState();
}

class _ChatListStudentScreenState extends State<ChatListStudentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregar();
    });
  }

  Future<void> _carregar() async {
    final userId = context.read<AuthProvider>().profile?.id;
    if (userId == null) return;

    // A RPC devolve também as denúncias anónimas em que o estudante participa
    // (nestas não existe `estudante_id`, por isso não apareciam na lista).
    await context.read<DenunciaProvider>().listarMinhasDenuncias(userId);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DenunciaProvider>();
    final conversas = provider.conversas;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensagens'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: provider.carregandoMinhas && conversas.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primario),
              )
            : conversas.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 80),
                      EmptyState(
                        icon: Icons.chat_bubble_outline,
                        mensagem: 'Sem conversas',
                        subtitulo:
                            'As suas mensagens com a Comissão de Ética aparecem aqui.',
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: conversas.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _ChatCardStudent(
                        conversa: conversas[index],
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ChatScreen(denuncia: conversas[index].denuncia),
                            ),
                          );
                          // Ao voltar, o resumo da conversa já foi actualizado.
                          if (context.mounted) _carregar();
                        },
                      );
                    },
                  ),
      ),
    );
  }
}

class _ChatCardStudent extends StatelessWidget {
  final DenunciaComMensagem conversa;
  final VoidCallback onTap;

  const _ChatCardStudent({
    required this.conversa,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final d = conversa.denuncia;
    final temMensagens = conversa.temMensagens;
    final naoLidas = conversa.naoLidas;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primario, AppColors.primarioClaro],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  d.anonima ? Icons.shield_outlined : Icons.person_outline,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            d.displayCategoria,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (conversa.ultimaMensagemData != null)
                          Text(
                            Formatters.data(conversa.ultimaMensagemData!),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.cinza,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      d.anonima
                          ? 'Código: ${d.codigo} • Anónima'
                          : 'Código: ${d.codigo}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.cinza,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            temMensagens
                                ? (conversa.ultimaMensagem!.length > 60
                                    ? '${conversa.ultimaMensagem!.substring(0, 60)}...'
                                    : conversa.ultimaMensagem!)
                                : 'Sem mensagens — toque para conversar',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: temMensagens
                                  ? AppColors.cinza
                                  : AppColors.cinza.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        if (naoLidas > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primario,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$naoLidas',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}