import 'package:expense_mate/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators', () {
    test('email returns null for valid email', () {
      expect(Validators.email('test@example.com'), isNull);
    });

    test('email returns error for invalid email', () {
      expect(Validators.email('invalid'), isNotNull);
      expect(Validators.email(''), isNotNull);
    });

    test('password requires minimum 8 characters', () {
      expect(Validators.password('12345678'), isNull);
      expect(Validators.password('short'), isNotNull);
    });

    test('confirmPassword matches password', () {
      expect(
        Validators.confirmPassword('password123', 'password123'),
        isNull,
      );
      expect(
        Validators.confirmPassword('different', 'password123'),
        isNotNull,
      );
    });

    test('amount validates positive numbers', () {
      expect(Validators.amount('100.50'), isNull);
      expect(Validators.amount('0'), isNotNull);
      expect(Validators.amount('abc'), isNotNull);
    });

    test('name requires at least 2 characters', () {
      expect(Validators.name('John'), isNull);
      expect(Validators.name('J'), isNotNull);
    });
  });
}
