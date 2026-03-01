import '../database/tables.dart';

/// Helper utilities for working with [Cycles] enum.
///
/// Provides conversion factors and calculations related to recurring transaction cycles.
class CyclesHelper {
  /// Returns the monthly factor for a given cycle.
  ///
  /// Used to calculate average monthly values from different cycle frequencies.
  /// For example, a daily cycle occurs ~30.436875 times per month, so its factor
  /// is 30.436875. A monthly cycle occurs once per month (factor 1.0).
  ///
  /// The base value 30.436875 represents the average days per month (365.2425 / 12).
  ///
  /// Returns:
  /// - Daily: 30.436875 (average days per month)
  /// - Weekly: 4.348125 (30.436875 / 7)
  /// - Monthly: 1.0
  /// - Quarterly: 0.333... (1/3)
  /// - Yearly: 0.083... (1/12)
  ///
  /// Example:
  /// ```dart
  /// final factor = CyclesHelper.monthlyFactorForCycle(Cycles.daily);
  /// final monthlyValue = dailyAmount * factor; // Convert daily to monthly
  /// ```
  static double monthlyFactorForCycle(Cycles cycle) {
    switch (cycle) {
      case Cycles.daily:
        return 30.436875;
      case Cycles.weekly:
        return 30.436875 / 7;
      case Cycles.monthly:
        return 1.0;
      case Cycles.quarterly:
        return 1.0 / 3.0;
      case Cycles.yearly:
        return 1.0 / 12.0;
    }
  }
}
