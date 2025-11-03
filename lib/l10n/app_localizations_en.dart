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

  @override
  String get insufficientBalance =>
      'Account has insufficient balance for this debit.';

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
  String get amount => 'Amount';

  @override
  String get pleaseEnterAnAmount => 'Please enter an amount!';

  @override
  String get invalidInput => 'Invalid input!';

  @override
  String get tooManyDecimalPlaces => 'Too many decimal places!';

  @override
  String get reason => 'Reason';

  @override
  String get pleaseEnterAReason => 'Please enter a reason!';

  @override
  String get reasonReservedForTransfer =>
      'This reason is reserved for transfers.';

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
  String get cannotDeleteAccount => 'Cannot Delete Account';

  @override
  String get accountHasReferencesArchiveInstead =>
      'This account has references and cannot be deleted. Would you like to archive it instead?';

  @override
  String get archive => 'Archive';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get confirmDeleteAccount =>
      'Are you sure you want to delete this account?';

  @override
  String get confirm => 'Confirm';

  @override
  String get unarchiveAccount => 'Unarchive Account';

  @override
  String get confirmUnarchiveAccount =>
      'Do you want to unarchive this account?';

  @override
  String error(String error) {
    return 'Error: $error';
  }

  @override
  String get noActiveAccounts => 'No active accounts yet. Tap + to add one!';

  @override
  String get archivedAccounts => 'Archived Accounts';

  @override
  String anErrorOccurred(String error) {
    return 'An error occurred: $error';
  }

  @override
  String get noBookingsYet => 'No bookings yet.';

  @override
  String get unknownAccount => 'Unknown Account';

  @override
  String get deleteBookingConfirmation => 'Delete Booking?';

  @override
  String get delete => 'Delete';
}
