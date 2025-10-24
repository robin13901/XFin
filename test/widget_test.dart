import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/main.dart';

void main() {
  testWidgets('App starts and displays the main screen', (WidgetTester tester) async {
    // Create an in-memory database for testing.
    final db = AppDatabase(NativeDatabase.memory());

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      Provider<AppDatabase>(
        create: (_) => db,
        dispose: (_, db) => db.close(),
        child: const MyApp(),
      ),
    );

    // Verify that the MainScreen is present.
    expect(find.byType(MainScreen), findsOneWidget);
  });
}
