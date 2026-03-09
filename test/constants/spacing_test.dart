import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/constants/spacing.dart';

void main() {
  group('Spacing numeric constants', () {
    test('tiny is 4.0', () {
      expect(Spacing.tiny, 4.0);
    });

    test('small is 8.0', () {
      expect(Spacing.small, 8.0);
    });

    test('medium is 16.0', () {
      expect(Spacing.medium, 16.0);
    });

    test('large is 24.0', () {
      expect(Spacing.large, 24.0);
    });

    test('huge is 32.0', () {
      expect(Spacing.huge, 32.0);
    });
  });

  group('Spacing vertical SizedBox widgets', () {
    test('vTiny has height 4.0', () {
      const widget = Spacing.vTiny as SizedBox;
      expect(widget.height, Spacing.tiny);
      expect(widget.width, isNull);
    });

    test('vSmall has height 8.0', () {
      const widget = Spacing.vSmall as SizedBox;
      expect(widget.height, Spacing.small);
      expect(widget.width, isNull);
    });

    test('vMedium has height 16.0', () {
      const widget = Spacing.vMedium as SizedBox;
      expect(widget.height, Spacing.medium);
      expect(widget.width, isNull);
    });

    test('vLarge has height 24.0', () {
      const widget = Spacing.vLarge as SizedBox;
      expect(widget.height, Spacing.large);
      expect(widget.width, isNull);
    });

    test('vHuge has height 32.0', () {
      const widget = Spacing.vHuge as SizedBox;
      expect(widget.height, Spacing.huge);
      expect(widget.width, isNull);
    });
  });

  group('Spacing horizontal SizedBox widgets', () {
    test('hTiny has width 4.0', () {
      const widget = Spacing.hTiny as SizedBox;
      expect(widget.width, Spacing.tiny);
      expect(widget.height, isNull);
    });

    test('hSmall has width 8.0', () {
      const widget = Spacing.hSmall as SizedBox;
      expect(widget.width, Spacing.small);
      expect(widget.height, isNull);
    });

    test('hMedium has width 16.0', () {
      const widget = Spacing.hMedium as SizedBox;
      expect(widget.width, Spacing.medium);
      expect(widget.height, isNull);
    });

    test('hLarge has width 24.0', () {
      const widget = Spacing.hLarge as SizedBox;
      expect(widget.width, Spacing.large);
      expect(widget.height, isNull);
    });

    test('hHuge has width 32.0', () {
      const widget = Spacing.hHuge as SizedBox;
      expect(widget.width, Spacing.huge);
      expect(widget.height, isNull);
    });
  });
}
