import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/database/connection/connection.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Connection Export', () {
    test('connect function is accessible', () {
      // The connection.dart file conditionally exports the correct implementation
      // On native platforms (IO), it should export native.dart
      // On web platforms, it should export web.dart
      // Otherwise, it exports stub.dart

      final executor = connect();
      
      // Should return a QueryExecutor (type depends on platform)
      expect(executor, isA<QueryExecutor>());
    });

    test('connect returns consistent type', () {
      final executor1 = connect();
      final executor2 = connect();

      expect(executor1.runtimeType, equals(executor2.runtimeType));
    });

    test('multiple connect calls work correctly', () {
      // Should be able to call connect multiple times without errors
      final executor1 = connect();
      final executor2 = connect();
      final executor3 = connect();

      expect(executor1, isA<QueryExecutor>());
      expect(executor2, isA<QueryExecutor>());
      expect(executor3, isA<QueryExecutor>());
    });
  });
}
