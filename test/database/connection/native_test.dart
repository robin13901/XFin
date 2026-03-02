import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/database/connection/native.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Native Connection', () {
    test('connect returns QueryExecutor', () {
      final executor = connect();
      expect(executor, isA<QueryExecutor>());
    });

    test('connect returns LazyDatabase', () {
      final executor = connect();
      expect(executor, isA<LazyDatabase>());
    });

    test('connect can be called multiple times', () {
      final executor1 = connect();
      final executor2 = connect();

      expect(executor1, isA<QueryExecutor>());
      expect(executor2, isA<QueryExecutor>());

      // Different instances
      expect(identical(executor1, executor2), isFalse);
    });

    test('LazyDatabase is created successfully', () {
      final executor = connect();
      expect(executor, isA<QueryExecutor>());
      expect(executor, isA<LazyDatabase>());
    });

    test('connection creates executor that can be ensured open', () async {
      final executor = connect();

      // LazyDatabase should be openable
      expect(executor, isA<LazyDatabase>());

      // The executor is lazy, so it won't actually open until used
      // This test just verifies it's the correct type
    });

    test('multiple connections are independent', () {
      final executor1 = connect();
      final executor2 = connect();
      final executor3 = connect();

      expect(executor1, isA<LazyDatabase>());
      expect(executor2, isA<LazyDatabase>());
      expect(executor3, isA<LazyDatabase>());

      // All should be different instances
      expect(identical(executor1, executor2), isFalse);
      expect(identical(executor2, executor3), isFalse);
      expect(identical(executor1, executor3), isFalse);
    });
  });
}
