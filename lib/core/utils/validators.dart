abstract final class Validators {
  static final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'E-mail obrigatório';
    if (!_emailRegex.hasMatch(value.trim())) return 'E-mail inválido';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Senha obrigatória';
    if (value.length < 6) return 'Mínimo de 6 caracteres';
    return null;
  }

  static String? required(String? value, [String field = 'Campo']) {
    if (value == null || value.trim().isEmpty) return '$field obrigatório';
    return null;
  }

  static String? numeric(String? value, [String field = 'Valor']) {
    if (value == null || value.trim().isEmpty) return '$field obrigatório';
    if (double.tryParse(value) == null) return '$field deve ser numérico';
    return null;
  }

  static String? range(String? value, double min, double max, [String field = 'Valor']) {
    final numError = numeric(value, field);
    if (numError != null) return numError;
    final num = double.parse(value!);
    if (num < min || num > max) return '$field deve estar entre $min e $max';
    return null;
  }
}
