import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/database/connection/stub.dart';

void main() {
  group('Stub Connection', () {
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
  });
}
