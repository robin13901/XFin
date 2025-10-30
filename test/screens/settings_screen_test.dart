import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xfin/providers/theme_provider.dart';
import 'package:xfin/screens/settings_screen.dart';

void main() {
  group('SettingsScreen', () {
    late ThemeProvider themeProvider;

    setUp(() async {
      // Mock SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      themeProvider = ThemeProvider();
      await themeProvider.loadTheme(); // Initial load
    });

    Future<void> pumpSettingsScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: themeProvider,
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
    }

    testWidgets('renders correctly', (WidgetTester tester) async {
      await pumpSettingsScreen(tester);

      expect(find.text('Einstellungen'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.byType(DropdownButton<ThemeMode>), findsOneWidget);
      // Default is System, only the selected item is visible.
      expect(find.text('System'), findsOneWidget);
    });

    testWidgets('tapping dropdown items changes theme and persists it', (WidgetTester tester) async {
      await pumpSettingsScreen(tester);

      // Open dropdown
      await tester.tap(find.byType(DropdownButton<ThemeMode>));
      await tester.pumpAndSettle();

      // Now we should find two "System" texts (the selected item and the one in the list)
      expect(find.text('System'), findsNWidgets(2));

      // Tap 'Light'
      await tester.tap(find.text('Light').last);
      await tester.pumpAndSettle();
      expect(themeProvider.themeMode, ThemeMode.light);

      // Verify it was persisted
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'light');


      // Open dropdown again
      await tester.tap(find.byType(DropdownButton<ThemeMode>));
      await tester.pumpAndSettle();

      // Tap 'Dark'
      await tester.tap(find.text('Dark').last);
      await tester.pumpAndSettle();
      expect(themeProvider.themeMode, ThemeMode.dark);
      expect(prefs.getString('theme_mode'), 'dark');


       // Open dropdown again
      await tester.tap(find.byType(DropdownButton<ThemeMode>));
      await tester.pumpAndSettle();

      // Tap 'System'
      await tester.tap(find.text('System').last);
      await tester.pumpAndSettle();
      expect(themeProvider.themeMode, ThemeMode.system);
      expect(prefs.getString('theme_mode'), 'system');
    });
  });
}
