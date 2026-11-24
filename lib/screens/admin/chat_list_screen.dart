import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/conversa_comissao.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../student/chat_screen.dart';

/// Conversas da Comissão de Ética com os denunciantes.
///
/// A lista vem da RPC `listar_conversas_comissao`, que traz o resumo de cada
/// conversa e quantas mensagens do estudante estão por responder — antes a
/// comissão via simply todas as denúncias, quase sempre sem conversa activa.
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatProvider _chatProvider = ChatProvider();
  List<ConversaComissao> _conversas = [];
  bool _aCarregar = true;
  String? _erro;
  bool _apenasComConversa = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregar();
    });
  }

  Future<void> _carregar() async {
    setState(() {
      _aCarregar = true;
      _erro = null;
    });

    try {
      final profile = context.read<AuthProvider>().profile;
      // O super admin vê todas as conversas; o admin da faculdade vê as suas.
      final faculdade = profile?.isSuperAdmin == true ? null : profile?.faculdade;

      final lista = await _chatProvider.listarConversas(faculdade: faculdade);

      if (!mounted) return;
      setState(() {
        _conversas = lista;
        _aCarregar = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível carregar as conversas.';
        _aCarregar = false;
      });
    }
  }

  List<ConversaComissao> get _visiveis {
    final pendentes = _conversas.where((c) => c.aguardaResposta).toList()
      ..sort((a, b) => (b.ultimaMensagemData ?? DateTime(0))
          .compareTo(a.ultimaMensagemData ?? DateTime(0)));
    final restantes =
        _conversas.where((c) => !c.aguardaResposta).toList()
          ..sort((a, b) => (b.ultimaMensagemData ?? b.denuncia.createdAt ?? DateTime(0))
              .compareTo(a.ultimaMensagemData ?? a.denuncia.createdAt ?? DateTime(0)));

    return [...pendentes, ...restantes];
  }

  @override
  Widget build(BuildContext context) {
    final lista = _apenasComConversa
        ? _visiveis.where((c) => c.temConversa || c.aguardaResposta).toList()
        : _visiveis;
    final totalPendentes =
        _conversas.where((c) => c.aguardaResposta).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensagens'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: _apenasComConversa
                ? 'Mostrar todas as denúncias'
                : 'Mostrar apenas conversas',
            icon: Icon(
              _apenasComConversa ? Icons.forum_outlined : Icons.inbox_outlined,
            ),
            onPressed: () =>
                setState(() => _apenasComConversa = !_apenasComConversa),
          ),
        ],
      ),
      body: _aCarregar
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primario),
            )
          : _erro != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.cloud_off_outlined,
                          size: 48,
                          color: AppColors.cinza,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _erro!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.cinza),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _carregar,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: lista.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 80),
                            EmptyState(
                              icon: Icons.chat_bubble_outline,
                              mensagem: 'Sem conversas',
                              subtitulo:
                                  'As mensagens dos denunciantes aparecem aqui.',
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: lista.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) => _ChatCard(
                            conversa: lista[index],
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    denuncia: lista[index].denuncia,
                                    isAdminView: true,
                                  ),
                                ),
                              );
                              if (context.mounted) _carregar();
                            },
                          ),
                        ),
                ),
      floatingActionButton: null,
      bottomNavigationBar: totalPendentes > 0
          ? Container(
              width: double.infinity,
              color: AppColors.primario,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                '$totalPendentes ${totalPendentes == 1 ? 'denunciante aguarda' : 'denunciantes aguardam'} resposta',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            )
          : null,
    );
  }
}

class _ChatCard extends StatelessWidget {
  final ConversaComissao conversa;
  final VoidCallback onTap;

  const _ChatCard({required this.conversa, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final d = conversa.denuncia;
    final nome = d.anonima ? 'Denunciante Anónimo' : 'Estudante';

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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primario, AppColors.primarioClaro],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      d.anonima ? Icons.shield_outlined : Icons.person_outline,
                      color: Colors.white,
                      size: 22,
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
                                '$nome • ${d.codigo}',
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
                        const SizedBox(height: 2),
                        Text(
                          '${d.displayCategoria} • ${d.faculdade}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.cinza,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (conversa.temConversa) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.cinzaClaro,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        conversa.ultimaMensagemRemetente == 'estudante'
                            ? Icons.person_outline
                            : Icons.support_agent_outlined,
                        size: 14,
                        color: AppColors.cinza,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          conversa.ultimaMensagem ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.forum_outlined,
                    size: 14,
                    color: AppColors.cinza,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    conversa.temConversa
                        ? '${conversa.totalMensagens} mensagens'
                        : 'Sem mensagens',
                    style: const TextStyle(fontSize: 11, color: AppColors.cinza),
                  ),
                  const Spacer(),
                  if (conversa.aguardaResposta)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.vermelho,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Aguarda resposta',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    Text(
                      'Abrir',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primario,
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