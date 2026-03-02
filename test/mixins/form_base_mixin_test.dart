import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/mixins/form_base_mixin.dart';
import 'package:xfin/providers/database_provider.dart';

/// Test widget that uses FormBaseMixin
class TestFormWidget extends StatefulWidget {
  const TestFormWidget({super.key});

  @override
  State<TestFormWidget> createState() => _TestFormWidgetState();
}

class _TestFormWidgetState extends State<TestFormWidget>
    with FormBaseMixin<TestFormWidget> {
  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          Text('Render Heavy: $renderHeavy'),
          ElevatedButton(
            onPressed: enableHeavyRendering,
            child: const Text('Enable Heavy'),
          ),
        ],
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DatabaseProvider dbProvider;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dbProvider = DatabaseProvider.instance;
    dbProvider.initialize(db);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('mixin initializes formKey', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<DatabaseProvider>.value(
        value: dbProvider,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: TestFormWidget()),
        ),
      ),
    );

    final state =
        tester.state<_TestFormWidgetState>(find.byType(TestFormWidget));

    expect(state.formKey, isNotNull);
    expect(state.formKey.currentState, isNotNull);
  });

  testWidgets('mixin initializes database from provider', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<DatabaseProvider>.value(
        value: dbProvider,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: TestFormWidget()),
        ),
      ),
    );

    final state =
        tester.state<_TestFormWidgetState>(find.byType(TestFormWidget));

    expect(identical(state.db, db), isTrue);
  });

  testWidgets('mixin initializes l10n', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<DatabaseProvider>.value(
        value: dbProvider,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: TestFormWidget()),
        ),
      ),
    );

    final state =
        tester.state<_TestFormWidgetState>(find.byType(TestFormWidget));

    expect(state.l10n, isNotNull);
    expect(state.l10n, isA<AppLocalizations>());
  });

  testWidgets('mixin initializes validator with l10n', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<DatabaseProvider>.value(
        value: dbProvider,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: TestFormWidget()),
        ),
      ),
    );

    final state =
        tester.state<_TestFormWidgetState>(find.byType(TestFormWidget));

    expect(state.validator, isNotNull);
    expect(state.validator.l10n, equals(state.l10n));
  });

  testWidgets('mixin initializes formFields', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<DatabaseProvider>.value(
        value: dbProvider,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: TestFormWidget()),
        ),
      ),
    );

    final state =
        tester.state<_TestFormWidgetState>(find.byType(TestFormWidget));

    expect(state.formFields, isNotNull);
    // FormFields uses validator and l10n internally but doesn't expose them
  });

  testWidgets('renderHeavy defaults to false', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<DatabaseProvider>.value(
        value: dbProvider,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: TestFormWidget()),
        ),
      ),
    );

    expect(find.text('Render Heavy: false'), findsOneWidget);
  });

  testWidgets('enableHeavyRendering sets renderHeavy to true',
      (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<DatabaseProvider>.value(
        value: dbProvider,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: TestFormWidget()),
        ),
      ),
    );

    expect(find.text('Render Heavy: false'), findsOneWidget);

    // Tap button to enable heavy rendering
    await tester.tap(find.text('Enable Heavy'));
    await tester.pump();

    expect(find.text('Render Heavy: true'), findsOneWidget);
  });

  testWidgets('enableHeavyRendering checks mounted state', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<DatabaseProvider>.value(
        value: dbProvider,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: TestFormWidget()),
        ),
      ),
    );

    final state =
        tester.state<_TestFormWidgetState>(find.byType(TestFormWidget));

    // Dispose the widget
    await tester.pumpWidget(Container());

    // Call enableHeavyRendering after disposal - should not crash
    state.enableHeavyRendering();

    // No errors expected
  });

  testWidgets('mixin initializes in didChangeDependencies', (tester) async {
    ValueNotifier<int> rebuildNotifier = ValueNotifier(0);

    await tester.pumpWidget(
      ChangeNotifierProvider<DatabaseProvider>.value(
        value: dbProvider,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ValueListenableBuilder<int>(
              valueListenable: rebuildNotifier,
              builder: (context, value, child) {
                return const TestFormWidget();
              },
            ),
          ),
        ),
      ),
    );

    final state =
        tester.state<_TestFormWidgetState>(find.byType(TestFormWidget));

    expect(state.formKey, isNotNull);
    expect(state.db, isNotNull);
    expect(state.l10n, isNotNull);

    // Trigger rebuild (didChangeDependencies will be called again)
    rebuildNotifier.value = 1;
    await tester.pump();

    // Everything should still work
    expect(state.formKey, isNotNull);
    expect(state.db, isNotNull);
    expect(state.l10n, isNotNull);

    rebuildNotifier.dispose();
  });

  testWidgets('formKey can be used to validate form', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<DatabaseProvider>.value(
        value: dbProvider,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: TestFormWidget()),
        ),
      ),
    );

    final state =
        tester.state<_TestFormWidgetState>(find.byType(TestFormWidget));

    // Validate form (should return true since it's empty)
    final isValid = state.formKey.currentState!.validate();
    expect(isValid, isTrue);
  });

  testWidgets('renderHeavy can be read multiple times', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<DatabaseProvider>.value(
        value: dbProvider,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: TestFormWidget()),
        ),
      ),
    );

    final state =
        tester.state<_TestFormWidgetState>(find.byType(TestFormWidget));

    expect(state.renderHeavy, isFalse);
    expect(state.renderHeavy, isFalse); // Can read multiple times

    state.enableHeavyRendering();
    await tester.pump();

    expect(state.renderHeavy, isTrue);
    expect(state.renderHeavy, isTrue); // Can read multiple times
  });

  testWidgets('enableHeavyRendering calls setState', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<DatabaseProvider>.value(
        value: dbProvider,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: TestFormWidget()),
        ),
      ),
    );

    expect(find.text('Render Heavy: false'), findsOneWidget);

    // Enable heavy rendering should cause rebuild via setState
    await tester.tap(find.text('Enable Heavy'));
    await tester.pump();

    // Verify that setState was called and widget rebuilt with new state
    expect(find.text('Render Heavy: true'), findsOneWidget);
    expect(find.text('Render Heavy: false'), findsNothing);
  });
}
