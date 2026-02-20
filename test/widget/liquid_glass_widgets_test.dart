void main() {
  // testWidgets('right placeholder keeps layout when hidden', (tester) async {
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Scaffold(
  //         body: LiquidGlassBottomNav(
  //           icons: const [Icons.one_k, Icons.two_k],
  //           labels: const ['One', 'Two'],
  //           keys: const [Key('one'), Key('two')],
  //           currentIndex: 0,
  //           onTap: (_) {},
  //           keepLeftPlaceholder: true,
  //           rightVisibleForIndices: const {1},
  //         ),
  //       ),
  //     ),
  //   );
  //
  //   expect(find.byKey(const Key('fab')), findsNothing);
  //   expect(find.byKey(const Key('one')), findsOneWidget);
  //
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Scaffold(
  //         body: LiquidGlassBottomNav(
  //           icons: const [Icons.one_k, Icons.two_k],
  //           labels: const ['One', 'Two'],
  //           keys: const [Key('one'), Key('two')],
  //           currentIndex: 1,
  //           onTap: (_) {},
  //           keepLeftPlaceholder: true,
  //           rightVisibleForIndices: const {1},
  //         ),
  //       ),
  //     ),
  //   );
  //
  //   await tester.pumpAndSettle();
  //   expect(find.byKey(const Key('fab')), findsOneWidget);
  // });
}
