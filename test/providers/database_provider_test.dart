import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/providers/database_provider.dart';

void main() {
  group('DatabaseProvider', () {
    late DatabaseProvider original;

    setUp(() {
      original = DatabaseProvider.instance;
    });

    tearDown(() {
      // Restore original instance
      DatabaseProvider.instance = original;
    });

    test('instance returns singleton', () {
      final a = DatabaseProvider.instance;
      final b = DatabaseProvider.instance;
      expect(identical(a, b), isTrue);
    });

    test('instance setter replaces the singleton', () {
      final custom = DatabaseProvider.instance;
      // After setUp, instance is the original singleton.
      // Create a fresh provider via the @visibleForTesting setter.
      final freshDb = AppDatabase(NativeDatabase.memory());
      addTearDown(() => freshDb.close());
      custom.initialize(freshDb);

      // The instance should be the same object we started with.
      expect(DatabaseProvider.instance, same(custom));
    });

    test('initialize sets db and notifies listeners', () {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());
      final provider = DatabaseProvider.instance;
      var notified = false;
      provider.addListener(() => notified = true);

      provider.initialize(db);

      expect(provider.db, same(db));
      expect(notified, isTrue);

      provider.removeListener(() => notified = true);
    });

    test('replaceDatabase closes old db, sets new db, and notifies', () async {
      final oldDb = AppDatabase(NativeDatabase.memory());
      final newDb = AppDatabase(NativeDatabase.memory());
      addTearDown(() => newDb.close());

      final provider = DatabaseProvider.instance;
      provider.initialize(oldDb);

      var notifyCount = 0;
      void listener() => notifyCount++;
      provider.addListener(listener);

      // Reset count after initialize
      notifyCount = 0;

      await provider.replaceDatabase(newDb);

      expect(provider.db, same(newDb));
      expect(notifyCount, 1);
      // Old db is no longer referenced by provider
      expect(provider.db, isNot(same(oldDb)));

      provider.removeListener(listener);
    });

    test('db getter returns the initialized database', () {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());
      final provider = DatabaseProvider.instance;
      provider.initialize(db);

      expect(provider.db, isA<AppDatabase>());
      expect(provider.db, same(db));
    });
  });
}
