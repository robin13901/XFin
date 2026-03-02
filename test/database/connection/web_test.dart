import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/database/connection/web.dart';

void main() {
  group('Web Connection', () {
    test('connect throws unsupported platform error', () {
      expect(
        () => connect(),
        throwsA(equals('Unsupported platform')),
      );
    });

    test('connect throws consistently', () {
      expect(() => connect(), throwsA(equals('Unsupported platform')));
      expect(() => connect(), throwsA(equals('Unsupported platform')));
    });

    test('error message is exactly "Unsupported platform"', () {
      try {
        connect();
        fail('Expected exception to be thrown');
      } catch (e) {
        expect(e, equals('Unsupported platform'));
        expect(e.toString(), equals('Unsupported platform'));
      }
    });

    test('web platform is not currently supported', () {
      // This test documents that web is currently stub implementation
      expect(() => connect(), throwsA(isA<String>()));
    });
  });
}
