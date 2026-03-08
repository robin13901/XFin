import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/widgets/nav_bar_controller.dart';

void main() {
  group('NavBarController', () {
    testWidgets('provides ValueNotifier to descendants', (tester) async {
      final notifier = ValueNotifier<bool>(true);

      ValueNotifier<bool>? captured;

      await tester.pumpWidget(
        MaterialApp(
          home: NavBarController(
            visible: notifier,
            child: Builder(
              builder: (context) {
                captured = NavBarController.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(captured, equals(notifier));
      expect(captured!.value, isTrue);

      notifier.dispose();
    });

    testWidgets('returns null when no NavBarController in tree',
        (tester) async {
      ValueNotifier<bool>? captured;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              captured = NavBarController.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(captured, isNull);
    });

    testWidgets('value changes are reflected', (tester) async {
      final notifier = ValueNotifier<bool>(true);

      await tester.pumpWidget(
        MaterialApp(
          home: NavBarController(
            visible: notifier,
            child: Builder(
              builder: (context) {
                final visible = NavBarController.of(context);
                return ValueListenableBuilder<bool>(
                  valueListenable: visible!,
                  builder: (context, value, _) {
                    return Text(value ? 'visible' : 'hidden');
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('visible'), findsOneWidget);

      notifier.value = false;
      await tester.pump();

      expect(find.text('hidden'), findsOneWidget);

      notifier.dispose();
    });
  });
}
