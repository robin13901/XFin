import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/database/connection/native.dart';

void main() {
  test('connect returns a LazyDatabase QueryExecutor', () {
    final executor = connect();

    expect(executor, isA<QueryExecutor>());
    expect(executor, isA<LazyDatabase>());
  });
}
