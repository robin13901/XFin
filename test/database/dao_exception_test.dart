import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/database/dao_exception.dart';

void main() {
  group('DaoValidationException', () {
    test('toString returns message without prefix', () {
      const e = DaoValidationException('Test error');
      expect(e.toString(), 'Test error');
    });

    test('message property is accessible', () {
      const e = DaoValidationException('Test error');
      expect(e.message, 'Test error');
    });

    test('implements Exception', () {
      const e = DaoValidationException('Test');
      expect(e, isA<Exception>());
    });
  });
}
