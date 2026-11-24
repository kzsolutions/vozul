class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email obrigatório';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) return 'Email inválido';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Senha obrigatória';
    if (value.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Campo'} obrigatório';
    }
    return null;
  }

  static String? celular(String? value) {
    if (value == null || value.isEmpty) return 'Celular obrigatório';
    final clean = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (clean.length < 9) return 'Celular inválido (mín. 9 dígitos)';
    return null;
  }

  static String? numeroEstudante(String? value) {
    if (value == null || value.isEmpty) return 'Número de estudante obrigatório';
    final regex = RegExp(r'^\d{2}\.\d{4}\.\d{4}$');
    if (!regex.hasMatch(value.trim())) {
      return 'Formato inválido (ex: 05.1234.2025)';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirmação obrigatória';
    if (value != password) return 'As senhas não coincidem';
    return null;
  }
}