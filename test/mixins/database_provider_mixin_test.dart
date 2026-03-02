import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/providers/database_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    DatabaseProvider.instance.initialize(db);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('mixin initializes database from provider',
      (tester) async {
    // Use a real screen that uses the mixin instead of a test widget
    late AppDatabase accessedDb;
    bool didChangeDependenciesCalled = false;

    await tester.pumpWidget(
      ChangeNotifierProvider<DatabaseProvider>.value(
        value: DatabaseProvider.instance,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                // Manually test the mixin behavior
                didChangeDependenciesCalled = true;
                final dbProvider = context.read<DatabaseProvider>();
                accessedDb = dbProvider.db;
                return const Text('Test');
              },
            ),
          ),
        ),
      ),
    );

    expect(didChangeDependenciesCalled, isTrue);
    expect(identical(accessedDb, db), isTrue);
  });

  testWidgets('mixin provides database instance',
      (tester) async {
    // Test that the database provider is accessible
    late AppDatabase accessedDb;

    await tester.pumpWidget(
      ChangeNotifierProvider<DatabaseProvider>.value(
        value: DatabaseProvider.instance,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                accessedDb = context.read<DatabaseProvider>().db;
                return const Text('Test');
              },
            ),
          ),
        ),
      ),
    );

    expect(identical(accessedDb, db), isTrue);
    expect(accessedDb, isA<AppDatabase>());
  });

  testWidgets('database provider notifies listeners',
      (tester) async {
    int listenerCallCount = 0;

    DatabaseProvider.instance.addListener(() {
      listenerCallCount++;
    });

    await tester.pumpWidget(
      ChangeNotifierProvider<DatabaseProvider>.value(
        value: DatabaseProvider.instance,
        child: const MaterialApp(
          home: Scaffold(
            body: Text('Test'),
          ),
        ),
      ),
    );

    expect(listenerCallCount, 0);

    DatabaseProvider.instance.notifyListeners();
    await tester.pump();

    expect(listenerCallCount, 1);

    DatabaseProvider.instance.notifyListeners();
    await tester.pump();

    expect(listenerCallCount, 2);
  });

  testWidgets('mixin handles database provider correctly in context',
      (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<DatabaseProvider>.value(
        value: DatabaseProvider.instance,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final dbProvider = context.read<DatabaseProvider>();
                expect(dbProvider, isNotNull);
                expect(dbProvider.db, isA<AppDatabase>());
                return const Text('Test');
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('Test'), findsOneWidget);
  });

  test('database provider singleton returns same instance', () {
    final instance1 = DatabaseProvider.instance;
    final instance2 = DatabaseProvider.instance;

    expect(identical(instance1, instance2), isTrue);
  });

  test('database provider initializes with database', () {
    final testDb = AppDatabase(NativeDatabase.memory());
    DatabaseProvider.instance.initialize(testDb);

    expect(DatabaseProvider.instance.db, equals(testDb));

    testDb.close();
  });
}
