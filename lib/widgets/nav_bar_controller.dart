import 'package:flutter/material.dart';

/// Provides a [ValueNotifier<bool>] that controls bottom nav bar visibility.
/// Used to hide the nav bar when filter panels or keyboards are shown.
class NavBarController extends InheritedWidget {
  final ValueNotifier<bool> visible;

  const NavBarController({
    super.key,
    required this.visible,
    required super.child,
  });

  static ValueNotifier<bool>? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<NavBarController>()
        ?.visible;
  }

  @override
  bool updateShouldNotify(NavBarController oldWidget) =>
      visible != oldWidget.visible;
}
