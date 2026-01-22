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
  String get valueAlreadyExists => 'Value already exists';

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
  String get back => 'Zurück';

  @override
  String get next => 'Next';

  @override
  String get info => 'Info';

  @override
  String get addAsset => 'Add Asset';

  @override
  String get noAssetsAddedYet => 'No assets added yet';

  @override
  String get cashInfo =>
      'Only FIAT currencies can be credited to cash accounts.';

  @override
  String get bankAccountInfo =>
      'Only the base currency can be credited to bank accounts.';

  @override
  String get portfolioInfo =>
      'All asset types can be credited to portfolio accounts.';

  @override
  String get cryptoWalletInfo =>
      'Only crypto assets can be credited to crypto wallets.';

  @override
  String get assetAlreadyAdded => 'Asset already added';

  @override
  String get bankAccount => 'Bank Account';

  @override
  String get cryptoWallet => 'Crypto Wallet';

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

  @override
  String get insufficientBalance => 'Insufficient balance';

  @override
  String get insufficientShares => 'Not enough shares';

  @override
  String get mergeBookings => 'Merge bookings?';

  @override
  String get mergeBookingsQuestion =>
      'A similar booking already exists. Do you want to merge them?';

  @override
  String get createNew => 'Create new';

  @override
  String get merge => 'Merge';

  @override
  String get date => 'Date';

  @override
  String get datetime => 'Time';

  @override
  String get amount => 'Amount';

  @override
  String get pleaseEnterAnAmount => 'Please enter an amount!';

  @override
  String get invalidInput => 'Invalid input!';

  @override
  String get tooManyDecimalPlaces => 'Too many decimal places!';

  @override
  String get tooManyCharacters => 'Too many characters';

  @override
  String get category => 'Category';

  @override
  String get pleaseEnterACategory => 'Please enter a category!';

  @override
  String get categoryReservedForTransfer =>
      'This category is reserved for transfers.';

  @override
  String get account => 'Account';

  @override
  String get pleaseSelectAnAccount => 'Please select an account!';

  @override
  String get notes => 'Notes';

  @override
  String get excludeFromAverage => 'Exclude from average';

  @override
  String get dateCannotBeInTheFuture => 'The date cannot be in the future.';

  @override
  String get accountHasReferencesArchiveInstead =>
      'This account has references and cannot be deleted. Would you like to archive it instead?';

  @override
  String get archive => 'Archive';

  @override
  String get confirm => 'Confirm';

  @override
  String get unarchiveAccount => 'Unarchive Account';

  @override
  String get confirmUnarchiveAccount =>
      'Do you want to unarchive this account?';

  @override
  String get error => 'Error';

  @override
  String get noActiveAccounts => 'No active accounts yet';

  @override
  String get archivedAccounts => 'Archived Accounts';

  @override
  String anErrorOccurred(String error) {
    return 'An error occurred: $error';
  }

  @override
  String get valueMustNotBeZero => 'Value can not be 0';

  @override
  String get noBookingsYet => 'No bookings yet';

  @override
  String get unknownAccount => 'Unknown Account';

  @override
  String get assets => 'Assets';

  @override
  String get noAssets => 'No assets yet';

  @override
  String get assetHasReferences =>
      'This asset has references and cannot be deleted.';

  @override
  String get assetName => 'Asset Name';

  @override
  String get pleaseEnterAssetName => 'Please enter an asset name';

  @override
  String get assetAlreadyExists => 'An asset with this name already exists';

  @override
  String get tickerSymbol => 'Ticker Symbol';

  @override
  String get currencySymbol => 'Currency Symbol';

  @override
  String get pleaseEnterATickerSymbol => 'Please enter a ticker symbol';

  @override
  String get tickerSymbolAlreadyExists =>
      'An asset with this ticker symbol already exists';

  @override
  String get stock => 'Stock';

  @override
  String get crypto => 'Crypto';

  @override
  String get fiat => 'Fiat';

  @override
  String get fund => 'Fund';

  @override
  String get derivative => 'Derivative';

  @override
  String get etf => 'ETF';

  @override
  String get bond => 'Bond';

  @override
  String get commodity => 'Commodity';

  @override
  String get value => 'Value';

  @override
  String get sharesOwned => 'Shares';

  @override
  String get costBasis => 'Cost Basis';

  @override
  String get netCostBasis => 'Net Cost Basis';

  @override
  String get brokerCostBasis => 'Broker Cost Basis';

  @override
  String get update => 'Update';

  @override
  String get ok => 'OK';

  @override
  String get trades => 'Trades';

  @override
  String get noTrades => 'No trades yet';

  @override
  String get pricePerShare => 'Price per Share';

  @override
  String get fee => 'Fee';

  @override
  String get clearingAccount => 'Clearing Account';

  @override
  String get investmentAccount => 'Investment Account';

  @override
  String get pleaseSelectADate => 'Please select date and time!';

  @override
  String get pleaseSelectAType => 'Please select a type!';

  @override
  String get pleaseSelectAnAsset => 'Please select an asset!';

  @override
  String get requiredField => '* Required field';

  @override
  String get pleaseEnterAValidNumber => 'Please enter a valid number!';

  @override
  String get pleaseEnterAValidFee => 'Please enter a valid fee!';

  @override
  String get asset => 'Asset';

  @override
  String get shares => 'Shares';

  @override
  String get profitAndLoss => 'Profit & Loss';

  @override
  String get tax => 'Tax';

  @override
  String get sendingAndReceivingMustDiffer =>
      'Sending and receiving account must differ';

  @override
  String get sendingAccount => 'Sending Account';

  @override
  String get receivingAccount => 'Receiving Account';

  @override
  String get pleaseSelectCurrency => 'Please select a currency!';

  @override
  String get selectCurrency => 'Select Currency';

  @override
  String get currencySelectionPrompt =>
      'Please select your base currency. This cannot be changed later.';

  @override
  String get returnOnInvestment => 'Return on Investment';

  @override
  String get actionCancelledDueToDataInconsistency =>
      'This action is not possible because it would lead to data inconsistency';

  @override
  String get onlyCryptoCanBeBookedOnCryptoWallet =>
      'Only crypto can be booked on a crypto wallet.';

  @override
  String get onlyBaseCurrencyCanBeBookedOnBankAccount =>
      'Only the base currency can be booked on a bank account.';

  @override
  String get onlyCurrenciesCanBeBookedOnCashAccount =>
      'Only currencies can be booked on a cash account.';

  @override
  String get valueMustBeGreaterZero => 'Value must be > 0';

  @override
  String get valueMustBeGreaterEqualZero => 'Value must be ≥ 0';

  @override
  String get valueCannotBeZero => 'Value must not be 0';

  @override
  String get noTransfersYet => 'No transfers yet';

  @override
  String get transfers => 'Transfers';

  @override
  String get isGenerated => 'Created by standing order';

  @override
  String get updateWouldBreakAccountBalanceHistory =>
      'The changes cannot be saved. The entered values would lead to inconsistencies in the account balance history of one or more of the accounts involved.';

  @override
  String get importDatabase => 'Import Database';

  @override
  String get exportDatabase => 'Export Database';

  @override
  String get importDatabaseWarning =>
      'Importing will replace all current data. This cannot be undone. Continue?';

  @override
  String get importFailed => 'Import failed.';

  @override
  String get exportFailed => 'Export failed.';

  @override
  String get fileSavedSuccessfully => 'File saved successfully.';

  @override
  String get selectedFileDoesNotExist => 'Selected file does not exist.';

  @override
  String get selectedFileCannotBeAccessed =>
      'Selected file cannot be accessed.';

  @override
  String get databaseReplacedSuccessfully => 'Database replaced successfully.';

  @override
  String get databaseReplacedButReopenFailed =>
      'Database replaced but reopen failed.';

  @override
  String get delete => 'Delete';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAsset => 'Delete Asset';

  @override
  String get deleteBooking => 'Delete Booking';

  @override
  String get deleteTrade => 'Delete Trade';

  @override
  String get deleteTransfer => 'Delete Transfer';

  @override
  String get deleteAccountConfirmation =>
      'Are you sure you want to delete this account?';

  @override
  String get deleteAssetConfirmation =>
      'Are you sure you want to delete this asset?';

  @override
  String get deleteBookingConfirmation =>
      'Are you sure you want to delete this booking?';

  @override
  String get deleteTradeConfirmation =>
      'Are you sure you want to delete this trade?';

  @override
  String get deleteTransferConfirmation =>
      'Are you sure you want to delete this transfer?';

  @override
  String get cannotDeleteAccount => 'Cannot Delete Account';

  @override
  String get cannotDeleteAsset => 'Cannot Delete Asset';

  @override
  String get cannotDeleteOrArchiveAccount =>
      'Löschen oder Archivieren nicht möglich';

  @override
  String get cannotDeleteOrArchiveAccountLong =>
      'Accounts can only be deleted when they have no references. This account has references and cannot be deleted.\n\nAccounts with references can be archived but only if the balance is 0.';
}
