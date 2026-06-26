import 'package:expense_mate/core/services/security_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SecurityService.hashPin', () {
    test('produces consistent hash for same PIN', () {
      final a = SecurityService.hashPin('1234');
      final b = SecurityService.hashPin('1234');
      expect(a, b);
    });

    test('produces different hash for different PINs', () {
      final a = SecurityService.hashPin('1234');
      final b = SecurityService.hashPin('5678');
      expect(a, isNot(b));
    });

    test('hash is 64 character hex string', () {
      final hash = SecurityService.hashPin('0000');
      expect(hash.length, 64);
      expect(RegExp(r'^[a-f0-9]+$').hasMatch(hash), isTrue);
    });
  });
}
