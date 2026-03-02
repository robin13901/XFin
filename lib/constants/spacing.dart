import 'package:flutter/material.dart';

/// Spacing constants for consistent padding and margins throughout the app.
class Spacing {
  Spacing._();

  // Numeric values
  static const double tiny = 4.0;
  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
  static const double huge = 32.0;

  // Vertical spacing widgets
  static const Widget vTiny = SizedBox(height: tiny);
  static const Widget vSmall = SizedBox(height: small);
  static const Widget vMedium = SizedBox(height: medium);
  static const Widget vLarge = SizedBox(height: large);
  static const Widget vHuge = SizedBox(height: huge);

  // Horizontal spacing widgets
  static const Widget hTiny = SizedBox(width: tiny);
  static const Widget hSmall = SizedBox(width: small);
  static const Widget hMedium = SizedBox(width: medium);
  static const Widget hLarge = SizedBox(width: large);
  static const Widget hHuge = SizedBox(width: huge);
}
