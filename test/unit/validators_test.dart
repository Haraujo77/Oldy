import 'package:flutter_test/flutter_test.dart';
import 'package:oldy/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('returns null for valid email', () {
      expect(Validators.email('user@example.com'), isNull);
    });

    test('returns null for email with dots and hyphens', () {
      expect(Validators.email('first.last@sub-domain.co'), isNull);
    });

    test('returns error for invalid email without @', () {
      expect(Validators.email('userexample.com'), isNotNull);
    });

    test('returns error for invalid email without domain', () {
      expect(Validators.email('user@'), isNotNull);
    });

    test('returns error for empty string', () {
      expect(Validators.email(''), 'E-mail obrigatório');
    });

    test('returns error for null', () {
      expect(Validators.email(null), 'E-mail obrigatório');
    });

    test('returns error for whitespace only', () {
      expect(Validators.email('   '), 'E-mail obrigatório');
    });

    test('trims whitespace before validation', () {
      expect(Validators.email(' user@example.com '), isNull);
    });
  });

  group('Validators.password', () {
    test('returns null for valid password (6+ chars)', () {
      expect(Validators.password('abc123'), isNull);
    });

    test('returns null for long password', () {
      expect(Validators.password('a' * 20), isNull);
    });

    test('returns error for too short password', () {
      expect(Validators.password('12345'), 'Mínimo de 6 caracteres');
    });

    test('returns error for single char', () {
      expect(Validators.password('a'), 'Mínimo de 6 caracteres');
    });

    test('returns error for empty string', () {
      expect(Validators.password(''), 'Senha obrigatória');
    });

    test('returns error for null', () {
      expect(Validators.password(null), 'Senha obrigatória');
    });
  });

  group('Validators.required', () {
    test('returns null for non-empty string', () {
      expect(Validators.required('hello'), isNull);
    });

    test('returns error for empty string with default field name', () {
      expect(Validators.required(''), 'Campo obrigatório');
    });

    test('returns error for null with default field name', () {
      expect(Validators.required(null), 'Campo obrigatório');
    });

    test('returns error for whitespace only', () {
      expect(Validators.required('   '), 'Campo obrigatório');
    });

    test('uses custom field name in error message', () {
      expect(Validators.required('', 'Nome'), 'Nome obrigatório');
    });
  });

  group('Validators.numeric', () {
    test('returns null for integer string', () {
      expect(Validators.numeric('42'), isNull);
    });

    test('returns null for decimal string', () {
      expect(Validators.numeric('3.14'), isNull);
    });

    test('returns null for negative number', () {
      expect(Validators.numeric('-7'), isNull);
    });

    test('returns error for non-numeric string', () {
      expect(Validators.numeric('abc'), 'Valor deve ser numérico');
    });

    test('returns error for empty string', () {
      expect(Validators.numeric(''), 'Valor obrigatório');
    });

    test('returns error for null', () {
      expect(Validators.numeric(null), 'Valor obrigatório');
    });

    test('uses custom field name', () {
      expect(Validators.numeric('abc', 'Peso'), 'Peso deve ser numérico');
    });
  });

  group('Validators.range', () {
    test('returns null for value within range', () {
      expect(Validators.range('50', 0, 100), isNull);
    });

    test('returns null for value at min boundary', () {
      expect(Validators.range('0', 0, 100), isNull);
    });

    test('returns null for value at max boundary', () {
      expect(Validators.range('100', 0, 100), isNull);
    });

    test('returns error for value below range', () {
      expect(Validators.range('-1', 0, 100), contains('entre'));
    });

    test('returns error for value above range', () {
      expect(Validators.range('101', 0, 100), contains('entre'));
    });

    test('returns numeric error for non-numeric input', () {
      expect(Validators.range('abc', 0, 100), 'Valor deve ser numérico');
    });

    test('returns required error for empty input', () {
      expect(Validators.range('', 0, 100), 'Valor obrigatório');
    });

    test('uses custom field name in range error', () {
      final result = Validators.range('200', 0, 100, 'Glicemia');
      expect(result, 'Glicemia deve estar entre 0.0 e 100.0');
    });

    test('decimal range works correctly', () {
      expect(Validators.range('36.8', 36.0, 37.5), isNull);
      expect(Validators.range('35.9', 36.0, 37.5), contains('entre'));
    });
  });
}
