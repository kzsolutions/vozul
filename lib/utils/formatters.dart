import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import 'package:flutter/material.dart';

class Formatters {
  static String dataHora(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  static String data(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String dataLonga(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('dd \'de\' MMMM \'de\' yyyy', 'pt_PT').format(date);
  }

  static String tamanhoArquivo(num bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String mesAno(DateTime date) {
    return DateFormat('MMM/yyyy', 'pt_PT').format(date);
  }

  static Color corStatus(String status) {
    switch (status) {
      case 'Recebida':
        return AppColors.statusRecebida;
      case 'Em análise':
        return AppColors.statusEmAnalise;
      case 'Investigação':
        return AppColors.statusInvestigacao;
      case 'Resolvida':
        return AppColors.statusResolvida;
      case 'Encerrada':
        return AppColors.statusEncerrada;
      default:
        return AppColors.cinza;
    }
  }

  static IconData iconeStatus(String status) {
    switch (status) {
      case 'Recebida':
        return Icons.mark_email_read_outlined;
      case 'Em análise':
        return Icons.manage_search_outlined;
      case 'Investigação':
        return Icons.fact_check_outlined;
      case 'Resolvida':
        return Icons.check_circle_outline;
      case 'Encerrada':
        return Icons.lock_outline;
      default:
        return Icons.help_outline;
    }
  }
}