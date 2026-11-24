import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/denuncia.dart';
import '../../utils/formatters.dart';
import '../student/chat_screen.dart';

class DenunciaDetailScreen extends StatelessWidget {
  final Denuncia denuncia;

  const DenunciaDetailScreen({super.key, required this.denuncia});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(denuncia.codigo),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Detalhes'),
              Tab(text: 'Chat com Estudante'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _DetalhesTab(denuncia: denuncia),
            ChatScreen(denuncia: denuncia, isAdminView: true),
          ],
        ),
      ),
    );
  }
}

class _DetalhesTab extends StatelessWidget {
  final Denuncia denuncia;

  const _DetalhesTab({required this.denuncia});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.security_outlined, color: AppColors.verde),
              const SizedBox(width: 8),
              Text(
                denuncia.anonima ? 'Denúncia anónima' : 'Denúncia identificada',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: denuncia.anonima
                      ? AppColors.verde
                      : AppColors.primario,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoBlock(
            titulo: 'Tipo de denúncia',
            icon: Icons.category_outlined,
            child: Text(
              denuncia.displayCategoria,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          _InfoBlock(
            titulo: 'Descrição',
            icon: Icons.description_outlined,
            child: Text(
              denuncia.descricao,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          _InfoBlock(
            titulo: 'Denunciado',
            icon: Icons.person_pin_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tipoDenunciado(denuncia.denunciadoTipo),
                  style: const TextStyle(fontSize: 15),
                ),
                if (denuncia.denunciadoNome != null &&
                    denuncia.denunciadoNome!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 15,
                        color: AppColors.cinza,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        denuncia.denunciadoNome!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
                if (denuncia.denunciadoNumero != null &&
                    denuncia.denunciadoNumero!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.numbers,
                        size: 15,
                        color: AppColors.cinza,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        denuncia.denunciadoNumero!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          _InfoBlock(
            titulo: 'Faculdade e Curso',
            icon: Icons.account_balance_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(denuncia.faculdade, style: const TextStyle(fontSize: 15)),
                if (denuncia.curso != null)
                  Text(
                    denuncia.curso!,
                    style: TextStyle(fontSize: 14, color: AppColors.cinza),
                  ),
              ],
            ),
          ),
          _InfoBlock(
            titulo: 'Data e Local',
            icon: Icons.location_on_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.event,
                      size: 15,
                      color: AppColors.cinza,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      Formatters.data(denuncia.dataOcorrido),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                if (denuncia.localOcorrido != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 15,
                        color: AppColors.cinza,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          denuncia.localOcorrido!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          _InfoBlock(
            titulo: 'Evidências',
            icon: Icons.attach_file,
            child: Row(
              children: [
                Icon(
                  denuncia.temProvas
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
                  size: 16,
                  color: denuncia.temProvas
                      ? AppColors.verde
                      : AppColors.amarelo,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    denuncia.temProvas
                        ? 'Foram anexadas provas a esta denúncia.'
                        : 'Sem provas anexadas pelo estudante.',
                    style: TextStyle(
                      fontSize: 14,
                      color: denuncia.temProvas
                          ? AppColors.verde
                          : AppColors.amarelo,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _InfoBlock(
            titulo: 'Informações do envio',
            icon: Icons.info_outline,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LinhaInfo(
                  label: 'Data de envio',
                  valor: Formatters.dataHora(denuncia.createdAt),
                ),
                _LinhaInfo(
                  label: 'Última atualização',
                  valor: Formatters.dataHora(denuncia.updatedAt),
                ),
                _LinhaInfo(
                  label: 'Status atual',
                  valor: denuncia.status,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _tipoDenunciado(String? tipo) {
    if (tipo == null) return 'Não informada';
    switch (tipo) {
      case 'docente':
        return 'Docente';
      case 'estudante':
        return 'Estudante';
      case 'funcionario':
        return 'Funcionário';
      default:
        return tipo;
    }
  }
}

class _InfoBlock extends StatelessWidget {
  final String titulo;
  final IconData icon;
  final Widget child;

  const _InfoBlock({
    required this.titulo,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Icon(icon, size: 18, color: AppColors.primario),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primario,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _LinhaInfo extends StatelessWidget {
  final String label;
  final String valor;

  const _LinhaInfo({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.cinza),
          ),
          const Spacer(),
          Text(
            valor,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}