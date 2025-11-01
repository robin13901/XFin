// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get accountName => 'Kontoname';

  @override
  String get pleaseEnterAName => 'Bitte geben Sie einen Namen ein';

  @override
  String get accountAlreadyExists =>
      'Ein Konto mit diesem Namen existiert bereits';

  @override
  String get initialBalance => 'Anfangssaldo';

  @override
  String get pleaseEnterABalance => 'Bitte geben Sie einen Saldo ein';

  @override
  String get invalidNumber => 'Ungültige Nummer';

  @override
  String get initialBalanceCannotBeNegative =>
      'Der Anfangssaldo darf nicht negativ sein';

  @override
  String get amountTooManyDecimalPlaces => 'Maximal 2 Nachkommastellen erlaubt';

  @override
  String get type => 'Typ';

  @override
  String get cash => 'Bargeld';

  @override
  String get portfolio => 'Portfolio';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get analysis => 'Analyse';

  @override
  String get accounts => 'Konten';

  @override
  String get bookings => 'Buchungen';

  @override
  String get more => 'Mehr';

  @override
  String get settings => 'Einstellungen';

  @override
  String get language => 'Sprache';

  @override
  String get english => 'Englisch';

  @override
  String get german => 'Deutsch';

  @override
  String get theme => 'Thema';

  @override
  String get system => 'System';

  @override
  String get light => 'Hell';

  @override
  String get dark => 'Dunkel';
}
