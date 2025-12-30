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
  String get valueAlreadyExists => 'Wert existiert bereits';

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
  String get back => 'Zurück';

  @override
  String get next => 'Weiter';

  @override
  String get info => 'Info';

  @override
  String get addAsset => 'Asset hinzufügen';

  @override
  String get noAssetsAddedYet => 'Noch keine Assets hinzugefügt';

  @override
  String get cashInfo => 'TODO...';

  @override
  String get bankAccountInfo => 'TODO...';

  @override
  String get portfolioInfo => 'TODO...';

  @override
  String get cryptoWalletInfo => 'TODO...';

  @override
  String get assetAlreadyAdded => 'Asset bereits hinzugefügt';

  @override
  String get bankAccount => 'Bankkonto';

  @override
  String get cryptoWallet => 'Krypto Wallet';

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
  String get insufficientBalance => 'Unzureichender Kontostand';

  @override
  String get insufficientShares => 'Nicht genügend Anteile';

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
  String get datetime => 'Zeitpunkt';

  @override
  String get amount => 'Betrag';

  @override
  String get pleaseEnterAnAmount => 'Bitte gib einen Betrag an';

  @override
  String get invalidInput => 'Ungültige Eingabe';

  @override
  String get tooManyDecimalPlaces => 'Zu viele Nachkommastellen';

  @override
  String get tooManyCharacters => 'Zu viele Zeichen';

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
  String get accountHasReferencesArchiveInstead =>
      'Dieses Konto hat Referenzen und kann nicht gelöscht werden. Möchten Sie es stattdessen archivieren?';

  @override
  String get archive => 'Archivieren';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get unarchiveAccount => 'Konto dearchivieren';

  @override
  String get confirmUnarchiveAccount =>
      'Möchten Sie dieses Konto dearchivieren?';

  @override
  String get error => 'Fehler';

  @override
  String get noActiveAccounts => 'Noch keine aktiven Konten vorhanden';

  @override
  String get archivedAccounts => 'Archivierte Konten';

  @override
  String anErrorOccurred(String error) {
    return 'Ein Fehler ist aufgetreten: $error';
  }

  @override
  String get valueMustNotBeZero => 'Wert darf nicht 0 sein';

  @override
  String get noBookingsYet => 'Noch keine Buchungen vorhanden';

  @override
  String get unknownAccount => 'Unbekanntes Konto';

  @override
  String get assets => 'Assets';

  @override
  String get noAssets => 'Noch keine Assets vorhanden';

  @override
  String get assetHasReferences =>
      'Dieses Asset hat Referenzen und kann nicht gelöscht werden.';

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
  String get currencySymbol => 'Währungssymbol';

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
  String get fiat => 'Fiat';

  @override
  String get fund => 'Fonds';

  @override
  String get derivative => 'Derivat';

  @override
  String get etf => 'ETF';

  @override
  String get bond => 'Anleihe';

  @override
  String get commodity => 'Rohstoff';

  @override
  String get value => 'Wert';

  @override
  String get sharesOwned => 'Anteile';

  @override
  String get costBasis => 'Kostenbasis';

  @override
  String get netCostBasis => 'Netto-Kostenbasis';

  @override
  String get brokerCostBasis => 'Broker-Kostenbasis';

  @override
  String get update => 'Aktualisieren';

  @override
  String get ok => 'OK';

  @override
  String get trades => 'Trades';

  @override
  String get noTrades => 'Noch keine Trades vorhanden';

  @override
  String get pricePerShare => 'Kurs';

  @override
  String get fee => 'Gebühr';

  @override
  String get clearingAccount => 'Verrechnungskonto';

  @override
  String get investmentAccount => 'Investment-Konto';

  @override
  String get pleaseSelectADate => 'Please select date and time!';

  @override
  String get pleaseSelectAType => 'Bitte wählen Sie einen Typ!';

  @override
  String get pleaseSelectAnAsset => 'Bitte wählen Sie ein Asset!';

  @override
  String get requiredField => '* Pflichtfeld';

  @override
  String get pleaseEnterAValidNumber =>
      'Bitte geben Sie eine gültige Zahl ein!';

  @override
  String get pleaseEnterAValidFee => 'Bitte geben Sie eine gültige Gebühr ein!';

  @override
  String get asset => 'Asset';

  @override
  String get shares => 'Anteile';

  @override
  String get profitAndLoss => 'Profit & Loss';

  @override
  String get tax => 'Steuer';

  @override
  String get sendingAndReceivingMustDiffer =>
      'Sender- und Empfängerkonto müssen unterschiedlich sein';

  @override
  String get sendingAccount => 'Senderkonto';

  @override
  String get receivingAccount => 'Empfängerkonto';

  @override
  String get pleaseSelectCurrency => 'Bitte wählen Sie eine Währung!';

  @override
  String get selectCurrency => 'Währung auswählen';

  @override
  String get currencySelectionPrompt =>
      'Bitte wählen Sie Ihre Basiswährung. Dies kann später nicht mehr geändert werden.';

  @override
  String get returnOnInvestment => 'Rendite';

  @override
  String get actionCancelledDueToDataInconsistency =>
      'Diese Aktion is nicht möglich, da sie zu Dateninkonsistenz führen würde';

  @override
  String get onlyCryptoCanBeBookedOnCryptoWallet =>
      'Nur Krypto kann auf eine Krypto Wallet gebucht werden.';

  @override
  String get onlyBaseCurrencyCanBeBookedOnBankAccount =>
      'Nur die Basiswährung kann auf einen Bank Account gebucht werden.';

  @override
  String get onlyCurrenciesCanBeBookedOnCashAccount =>
      'Nur Währungen können auf einen Cash Account gebucht werden.';

  @override
  String get valueMustBeGreaterZero => 'Wert muss > 0 sein';

  @override
  String get valueMustBeGreaterEqualZero => 'Wert muss ≥ 0 sein';

  @override
  String get valueCannotBeZero => 'Wert darf nicht 0 sein';

  @override
  String get noTransfersYet => 'Noch keine Überweisungen vorhanden';

  @override
  String get transfers => 'Überweisung';

  @override
  String get isGenerated => 'Erstellt durch Dauerauftrag';

  @override
  String get updateWouldBreakAccountBalanceHistory =>
      'Die Änderungen können nicht gespeichert werden. Die eingegebenen Werte würden zu Inkonsistenzen im Verlauf des Kontostandes eines oder mehrerer beteiligter Konten führen.';

  @override
  String get delete => 'Löschen';

  @override
  String get deleteAccount => 'Konto löschen';

  @override
  String get deleteAsset => 'Asset löschen';

  @override
  String get deleteBooking => 'Buchung löschen';

  @override
  String get deleteTrade => 'Trade löschen';

  @override
  String get deleteTransfer => 'Überweisung löschen';

  @override
  String get deleteAccountConfirmation =>
      'Sind Sie sicher, dass Sie dieses Konto löschen möchten?';

  @override
  String get deleteAssetConfirmation =>
      'Sind Sie sicher, dass Sie dieses Asset löschen möchten?';

  @override
  String get deleteBookingConfirmation =>
      'Sind Sie sicher, dass Sie diese Buchung löschen möchten?';

  @override
  String get deleteTradeConfirmation =>
      'Sind Sie sicher, dass Sie diesen Trade löschen möchten?';

  @override
  String get deleteTransferConfirmation =>
      'Sind Sie sicher, dass Sie diese Überweisung löschen möchten?';

  @override
  String get cannotDeleteAccount => 'Konto kann nicht gelöscht werden';

  @override
  String get cannotDeleteAsset => 'Asset kann nicht gelöscht werden';

  @override
  String get cannotDeleteOrArchiveAccount =>
      'Löschen oder Archivieren nicht möglich';

  @override
  String get cannotDeleteOrArchiveAccountLong =>
      'Konten können nur gelöscht werden, wenn sie keine Referenzen mehr haben. Dieses Konto hat Referenzen und kann nicht gelöscht werden.\n\nKonten mit Referenzen können archiviert werden, jedoch nur dann wenn der Saldo 0 beträgt.';
}
