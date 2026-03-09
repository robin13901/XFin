import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/utils/snappy_scroll_physics.dart';

void main() {
  group('SnappyPageScrollPhysics', () {
    const physics = SnappyPageScrollPhysics();

    test('minFlingDistance is 1.0', () {
      expect(physics.minFlingDistance, 1.0);
    });

    test('minFlingVelocity is 15.0', () {
      expect(physics.minFlingVelocity, 15.0);
    });

    test('maxFlingVelocity is 20000.0', () {
      expect(physics.maxFlingVelocity, 20000.0);
    });

    test('applyTo returns SnappyPageScrollPhysics', () {
      final applied = physics.applyTo(const ClampingScrollPhysics());
      expect(applied, isA<SnappyPageScrollPhysics>());
    });

    test('applyTo with null ancestor returns SnappyPageScrollPhysics', () {
      final applied = physics.applyTo(null);
      expect(applied, isA<SnappyPageScrollPhysics>());
    });

    group('carriedMomentum', () {
      test('positive velocity within clamp', () {
        // 500 is within 0..10000, so result = 1 * 500 * 12 = 6000
        expect(physics.carriedMomentum(500.0), 6000.0);
      });

      test('negative velocity within clamp', () {
        // -500: sign=-1, abs=500, clamp=500, result = -1 * 500 * 12 = -6000
        expect(physics.carriedMomentum(-500.0), -6000.0);
      });

      test('positive velocity above clamp', () {
        // 15000: sign=1, abs=15000, clamp=10000, result = 1 * 10000 * 12 = 120000
        expect(physics.carriedMomentum(15000.0), 120000.0);
      });

      test('negative velocity above clamp', () {
        // -15000: sign=-1, abs=15000, clamp=10000, result = -1 * 10000 * 12 = -120000
        expect(physics.carriedMomentum(-15000.0), -120000.0);
      });

      test('zero velocity', () {
        expect(physics.carriedMomentum(0.0), 0.0);
      });
    });

    group('spring', () {
      test('has mass 0.3', () {
        expect(physics.spring.mass, 0.3);
      });

      test('has stiffness 300.0', () {
        expect(physics.spring.stiffness, 300.0);
      });

      test('spring description is valid', () {
        final spring = physics.spring;
        expect(spring, isA<SpringDescription>());
        expect(spring.damping, isPositive);
      });
    });
  });
}
