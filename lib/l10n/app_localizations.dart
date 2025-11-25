import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @accountName.
  ///
  /// In en, this message translates to:
  /// **'Account Name'**
  String get accountName;

  /// No description provided for @pleaseEnterAName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get pleaseEnterAName;

  /// No description provided for @accountAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'An account with this name already exists'**
  String get accountAlreadyExists;

  /// No description provided for @initialBalance.
  ///
  /// In en, this message translates to:
  /// **'Initial Balance'**
  String get initialBalance;

  /// No description provided for @pleaseEnterABalance.
  ///
  /// In en, this message translates to:
  /// **'Please enter a balance'**
  String get pleaseEnterABalance;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get invalidNumber;

  /// No description provided for @initialBalanceCannotBeNegative.
  ///
  /// In en, this message translates to:
  /// **'Initial balance cannot be negative'**
  String get initialBalanceCannotBeNegative;

  /// No description provided for @amountTooManyDecimalPlaces.
  ///
  /// In en, this message translates to:
  /// **'Maximum of 2 decimal places allowed'**
  String get amountTooManyDecimalPlaces;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @portfolio.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get portfolio;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @analysis.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get analysis;

  /// No description provided for @accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// No description provided for @bookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookings;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @german.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get german;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @insufficientBalance.
  ///
  /// In en, this message translates to:
  /// **'Insufficient balance'**
  String get insufficientBalance;

  /// No description provided for @insufficientShares.
  ///
  /// In en, this message translates to:
  /// **'Not enough shares'**
  String get insufficientShares;

  /// No description provided for @mergeBookings.
  ///
  /// In en, this message translates to:
  /// **'Merge bookings?'**
  String get mergeBookings;

  /// No description provided for @mergeBookingsQuestion.
  ///
  /// In en, this message translates to:
  /// **'A similar booking already exists. Do you want to merge them?'**
  String get mergeBookingsQuestion;

  /// No description provided for @createNew.
  ///
  /// In en, this message translates to:
  /// **'Create new'**
  String get createNew;

  /// No description provided for @merge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get merge;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @datetime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get datetime;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @pleaseEnterAnAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter an amount!'**
  String get pleaseEnterAnAmount;

  /// No description provided for @invalidInput.
  ///
  /// In en, this message translates to:
  /// **'Invalid input!'**
  String get invalidInput;

  /// No description provided for @tooManyDecimalPlaces.
  ///
  /// In en, this message translates to:
  /// **'Too many decimal places!'**
  String get tooManyDecimalPlaces;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @pleaseEnterACategory.
  ///
  /// In en, this message translates to:
  /// **'Please enter a category!'**
  String get pleaseEnterACategory;

  /// No description provided for @categoryReservedForTransfer.
  ///
  /// In en, this message translates to:
  /// **'This category is reserved for transfers.'**
  String get categoryReservedForTransfer;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @pleaseSelectAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Please select an account!'**
  String get pleaseSelectAnAccount;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @excludeFromAverage.
  ///
  /// In en, this message translates to:
  /// **'Exclude from average'**
  String get excludeFromAverage;

  /// No description provided for @dateCannotBeInTheFuture.
  ///
  /// In en, this message translates to:
  /// **'The date cannot be in the future.'**
  String get dateCannotBeInTheFuture;

  /// No description provided for @cannotDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Cannot Delete Account'**
  String get cannotDeleteAccount;

  /// No description provided for @accountHasReferencesArchiveInstead.
  ///
  /// In en, this message translates to:
  /// **'This account has references and cannot be deleted. Would you like to archive it instead?'**
  String get accountHasReferencesArchiveInstead;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @confirmDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this account?'**
  String get confirmDeleteAccount;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @unarchiveAccount.
  ///
  /// In en, this message translates to:
  /// **'Unarchive Account'**
  String get unarchiveAccount;

  /// No description provided for @confirmUnarchiveAccount.
  ///
  /// In en, this message translates to:
  /// **'Do you want to unarchive this account?'**
  String get confirmUnarchiveAccount;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String error(String error);

  /// No description provided for @noActiveAccounts.
  ///
  /// In en, this message translates to:
  /// **'No active accounts yet'**
  String get noActiveAccounts;

  /// No description provided for @archivedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Archived Accounts'**
  String get archivedAccounts;

  /// No description provided for @anErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred: {error}'**
  String anErrorOccurred(String error);

  /// No description provided for @noBookingsYet.
  ///
  /// In en, this message translates to:
  /// **'No bookings yet'**
  String get noBookingsYet;

  /// No description provided for @unknownAccount.
  ///
  /// In en, this message translates to:
  /// **'Unknown Account'**
  String get unknownAccount;

  /// No description provided for @deleteBookingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete Booking?'**
  String get deleteBookingConfirmation;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @assets.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get assets;

  /// No description provided for @noAssets.
  ///
  /// In en, this message translates to:
  /// **'No assets yet'**
  String get noAssets;

  /// No description provided for @cannotDeleteAsset.
  ///
  /// In en, this message translates to:
  /// **'Cannot Delete Asset'**
  String get cannotDeleteAsset;

  /// No description provided for @assetHasReferences.
  ///
  /// In en, this message translates to:
  /// **'This asset has references and cannot be deleted.'**
  String get assetHasReferences;

  /// No description provided for @deleteAsset.
  ///
  /// In en, this message translates to:
  /// **'Delete Asset'**
  String get deleteAsset;

  /// No description provided for @confirmDeleteAsset.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this asset?'**
  String get confirmDeleteAsset;

  /// No description provided for @assetName.
  ///
  /// In en, this message translates to:
  /// **'Asset Name'**
  String get assetName;

  /// No description provided for @pleaseEnterAssetName.
  ///
  /// In en, this message translates to:
  /// **'Please enter an asset name'**
  String get pleaseEnterAssetName;

  /// No description provided for @assetAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'An asset with this name already exists'**
  String get assetAlreadyExists;

  /// No description provided for @tickerSymbol.
  ///
  /// In en, this message translates to:
  /// **'Ticker Symbol'**
  String get tickerSymbol;

  /// No description provided for @pleaseEnterATickerSymbol.
  ///
  /// In en, this message translates to:
  /// **'Please enter a ticker symbol'**
  String get pleaseEnterATickerSymbol;

  /// No description provided for @tickerSymbolAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'An asset with this ticker symbol already exists'**
  String get tickerSymbolAlreadyExists;

  /// No description provided for @stock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stock;

  /// No description provided for @crypto.
  ///
  /// In en, this message translates to:
  /// **'Crypto'**
  String get crypto;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @etf.
  ///
  /// In en, this message translates to:
  /// **'ETF'**
  String get etf;

  /// No description provided for @bond.
  ///
  /// In en, this message translates to:
  /// **'Bond'**
  String get bond;

  /// No description provided for @commodity.
  ///
  /// In en, this message translates to:
  /// **'Commodity'**
  String get commodity;

  /// No description provided for @value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get value;

  /// No description provided for @sharesOwned.
  ///
  /// In en, this message translates to:
  /// **'Shares'**
  String get sharesOwned;

  /// No description provided for @netCostBasis.
  ///
  /// In en, this message translates to:
  /// **'Net Cost Basis'**
  String get netCostBasis;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @trades.
  ///
  /// In en, this message translates to:
  /// **'Trades'**
  String get trades;

  /// No description provided for @noTrades.
  ///
  /// In en, this message translates to:
  /// **'No trades yet'**
  String get noTrades;

  /// No description provided for @pricePerShare.
  ///
  /// In en, this message translates to:
  /// **'Price per Share'**
  String get pricePerShare;

  /// No description provided for @tradingFee.
  ///
  /// In en, this message translates to:
  /// **'Trading Fee'**
  String get tradingFee;

  /// No description provided for @clearingAccount.
  ///
  /// In en, this message translates to:
  /// **'Clearing Account'**
  String get clearingAccount;

  /// No description provided for @portfolioAccount.
  ///
  /// In en, this message translates to:
  /// **'Portfolio Account'**
  String get portfolioAccount;

  /// No description provided for @pleaseSelectADate.
  ///
  /// In en, this message translates to:
  /// **'Please select date and time!'**
  String get pleaseSelectADate;

  /// No description provided for @pleaseSelectAType.
  ///
  /// In en, this message translates to:
  /// **'Please select a type!'**
  String get pleaseSelectAType;

  /// No description provided for @pleaseSelectAnAsset.
  ///
  /// In en, this message translates to:
  /// **'Please select an asset!'**
  String get pleaseSelectAnAsset;

  /// No description provided for @pleaseEnterAValue.
  ///
  /// In en, this message translates to:
  /// **'Please enter a value!'**
  String get pleaseEnterAValue;

  /// No description provided for @pleaseEnterAValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number!'**
  String get pleaseEnterAValidNumber;

  /// No description provided for @pleaseEnterAValidFee.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid fee!'**
  String get pleaseEnterAValidFee;

  /// No description provided for @asset.
  ///
  /// In en, this message translates to:
  /// **'Asset'**
  String get asset;

  /// No description provided for @shares.
  ///
  /// In en, this message translates to:
  /// **'Shares'**
  String get shares;

  /// No description provided for @profitAndLoss.
  ///
  /// In en, this message translates to:
  /// **'Profit & Loss'**
  String get profitAndLoss;

  /// No description provided for @tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// No description provided for @pleaseSelectCurrency.
  ///
  /// In en, this message translates to:
  /// **'Please select a currency!'**
  String get pleaseSelectCurrency;

  /// No description provided for @selectCurrency.
  ///
  /// In en, this message translates to:
  /// **'Select Currency'**
  String get selectCurrency;

  /// No description provided for @currencySelectionPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please select your base currency. This cannot be changed later.'**
  String get currencySelectionPrompt;

  /// No description provided for @returnOnInvestment.
  ///
  /// In en, this message translates to:
  /// **'Return on Investment'**
  String get returnOnInvestment;

  /// No description provided for @actionCancelledDueToDataInconsistency.
  ///
  /// In en, this message translates to:
  /// **'This action is not possible because it would lead to data inconsistency'**
  String get actionCancelledDueToDataInconsistency;

  /// No description provided for @valueMustBeGreaterZero.
  ///
  /// In en, this message translates to:
  /// **'Value must be > 0'**
  String get valueMustBeGreaterZero;

  /// No description provided for @valueMustBeGreaterEqualZero.
  ///
  /// In en, this message translates to:
  /// **'Value must be ≥ 0'**
  String get valueMustBeGreaterEqualZero;

  /// No description provided for @valueCannotBeZero.
  ///
  /// In en, this message translates to:
  /// **'Value must not be 0'**
  String get valueCannotBeZero;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
