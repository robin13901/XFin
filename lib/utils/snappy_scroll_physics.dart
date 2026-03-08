import 'package:flutter/material.dart';

class SnappyPageScrollPhysics extends PageScrollPhysics {
  const SnappyPageScrollPhysics({super.parent});

  @override
  SnappyPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SnappyPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double get minFlingDistance => 1.0;

  @override
  double get minFlingVelocity => 15.0;

  @override
  double get maxFlingVelocity => 20000.0;

  @override
  double carriedMomentum(double existingVelocity) =>
      existingVelocity.sign * existingVelocity.abs().clamp(0.0, 10000.0) * 12;

  @override
  SpringDescription get spring => SpringDescription.withDampingRatio(
        mass: 0.3,
        stiffness: 300.0,
        ratio: 0.8,
      );
}
