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

  @override
  String get insufficientBalance =>
      'Konto hat nicht genügend Guthaben für diese Abbuchung.';

  @override
  String get mergeBookings => 'Buchungen zusammenführen?';

  @override
  String get mergeBookingsQuestion =>
      'Eine ähnliche Buchung existiert bereits. Möchten Sie diese zusammenführen?';

  @override
  String get createNew => 'Neu erstellen';

  @override
  String get merge => 'Zusammenführen';

  @override
  String get date => 'Datum';

  @override
  String get amount => 'Betrag';

  @override
  String get pleaseEnterAnAmount => 'Bitte gib einen Betrag an!';

  @override
  String get invalidInput => 'Ungültige Eingabe!';

  @override
  String get tooManyDecimalPlaces => 'Zu viele Nachkommastellen!';

  @override
  String get category => 'Kategorie';

  @override
  String get pleaseEnterACategory => 'Bitte gib eine Kategorie an!';

  @override
  String get categoryReservedForTransfer =>
      'Diese Kategorie ist für Überweisungen reserviert.';

  @override
  String get account => 'Konto';

  @override
  String get pleaseSelectAnAccount => 'Bitte wähle ein Konto!';

  @override
  String get notes => 'Notizen';

  @override
  String get excludeFromAverage => 'Vom Durchschnitt ausschließen';

  @override
  String get dateCannotBeInTheFuture =>
      'Das Datum darf nicht in der Zukunft liegen.';

  @override
  String get cannotDeleteAccount => 'Konto kann nicht gelöscht werden';

  @override
  String get accountHasReferencesArchiveInstead =>
      'Dieses Konto hat Referenzen und kann nicht gelöscht werden. Möchten Sie es stattdessen archivieren?';

  @override
  String get archive => 'Archivieren';

  @override
  String get deleteAccount => 'Konto löschen';

  @override
  String get confirmDeleteAccount =>
      'Sind Sie sicher, dass Sie dieses Konto löschen möchten?';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get unarchiveAccount => 'Konto dearchivieren';

  @override
  String get confirmUnarchiveAccount =>
      'Möchten Sie dieses Konto dearchivieren?';

  @override
  String error(String error) {
    return 'Fehler: $error';
  }

  @override
  String get noActiveAccounts =>
      'Noch keine aktiven Konten. Tippe auf +, um eins hinzuzufügen!';

  @override
  String get archivedAccounts => 'Archivierte Konten';

  @override
  String anErrorOccurred(String error) {
    return 'Ein Fehler ist aufgetreten: $error';
  }

  @override
  String get noBookingsYet => 'Noch keine Buchungen vorhanden.';

  @override
  String get unknownAccount => 'Unbekanntes Konto';

  @override
  String get deleteBookingConfirmation => 'Buchung löschen?';

  @override
  String get delete => 'Löschen';

  @override
  String get assets => 'Assets';

  @override
  String get noAssets =>
      'Noch keine Assets vorhanden. Tippe auf +, um eins hinzuzufügen!';

  @override
  String get cannotDeleteAsset => 'Asset kann nicht gelöscht werden';

  @override
  String get assetHasReferences =>
      'Dieses Asset hat Referenzen und kann nicht gelöscht werden.';

  @override
  String get deleteAsset => 'Asset löschen';

  @override
  String get confirmDeleteAsset =>
      'Sind Sie sicher, dass Sie dieses Asset löschen möchten?';

  @override
  String get assetName => 'Asset Name';

  @override
  String get pleaseEnterAssetName => 'Bitte geben Sie einen Asset-Namen ein';

  @override
  String get assetAlreadyExists =>
      'Ein Asset mit diesem Namen existiert bereits';

  @override
  String get tickerSymbol => 'Tickersymbol';

  @override
  String get pleaseEnterATickerSymbol => 'Bitte geben Sie ein Tickersymbol ein';

  @override
  String get tickerSymbolAlreadyExists =>
      'Ein Asset mit diesem Tickersymbol existiert bereits';

  @override
  String get stock => 'Aktie';

  @override
  String get crypto => 'Krypto';

  @override
  String get currency => 'Währung';

  @override
  String get commodity => 'Rohstoff';

  @override
  String get value => 'Wert';

  @override
  String get sharesOwned => 'Anteile';

  @override
  String get netCostBasis => 'Netto-Kostenbasis';

  @override
  String get update => 'Aktualisieren';

  @override
  String get ok => 'OK';
}
