import 'dart:ui';

import 'package:xfin/l10n/app_localizations.dart';

/// Helper to get AppLocalizations for non-widget tests.
AppLocalizations getTestLocalizations() {
  return lookupAppLocalizations(const Locale('en'));
}
