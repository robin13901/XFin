// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get accountName => 'Account Name';

  @override
  String get pleaseEnterAName => 'Please enter a name';

  @override
  String get accountAlreadyExists => 'An account with this name already exists';

  @override
  String get initialBalance => 'Initial Balance';

  @override
  String get pleaseEnterABalance => 'Please enter a balance';

  @override
  String get invalidNumber => 'Invalid number';

  @override
  String get initialBalanceCannotBeNegative =>
      'Initial balance cannot be negative';

  @override
  String get amountTooManyDecimalPlaces =>
      'Maximum of 2 decimal places allowed';

  @override
  String get type => 'Type';

  @override
  String get cash => 'Cash';

  @override
  String get portfolio => 'Portfolio';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get analysis => 'Analysis';

  @override
  String get accounts => 'Accounts';

  @override
  String get bookings => 'Bookings';

  @override
  String get more => 'More';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get german => 'German';

  @override
  String get theme => 'Theme';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';
}
