import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/denuncia.dart';
import '../student/student_shell.dart';
import '../student/chat_screen.dart';

class DenunciaSucessoScreen extends StatelessWidget {
  final Denuncia denuncia;

  const DenunciaSucessoScreen({super.key, required this.denuncia});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.verdeClaro,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: AppColors.verde,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Denúncia recebida com sucesso!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primario,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                denuncia.anonima
                    ? 'A sua denúncia foi enviada anonimamente.'
                    : 'A sua denúncia foi enviada.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.cinza),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primarioClaro),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Guarde este código para acompanhar:',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.cinza,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primario,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        denuncia.codigo,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (denuncia.anonima)
                      const Text(
                        'Este código ficou guardado no separador "Acompanhar" para consultar depois.',
                        style: TextStyle(fontSize: 12, color: AppColors.cinza),
                        textAlign: TextAlign.center,
                      )
                    else
                      const Text(
                        'Pode acompanhar esta denúncia no separador "Acompanhar".',
                        style: TextStyle(fontSize: 12, color: AppColors.cinza),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              if (!denuncia.anonima || true) ...[
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
                const SizedBox(height: 12),
              ],
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const StudentShell()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.home_outlined),
                label: const Text('Voltar ao Início'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}