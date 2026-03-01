import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/widgets/more_pane.dart';

void main() {
  testWidgets('more pane shows calendar item', (tester) async {
    final navBarVisible = ValueNotifier<bool>(true);
    final navKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showMorePane(
                  context: context,
                  navBarKey: navKey,
                  navBarVisible: navBarVisible,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Calendar'), findsOneWidget);
  });
}
