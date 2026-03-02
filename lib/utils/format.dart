import 'package:intl/intl.dart';
import 'package:xfin/providers/base_currency_provider.dart';

import '../database/tables.dart';
import '../l10n/app_localizations.dart';

final dateFormat = DateFormat('dd.MM.yyyy');
final dateTimeFormat = DateFormat('dd.MM.yyyy, HH:mm');

final NumberFormat _currencyFormat =
    NumberFormat.currency(locale: 'de_DE', symbol: BaseCurrencyProvider.symbol);

int dateTimeToInt(DateTime dt) {
  return int.parse(DateFormat('yyyyMMdd').format(dt));
}

DateTime? intToDateTime(int i) {
  final s = i.toString();

  if (s.length == 8) {
    return DateTime.parse(
      '${s.substring(0, 4)}-${s.substring(4, 6)}-${s.substring(6, 8)}',
    );
  } else if (s.length == 14) {
    return DateTime.parse(
      '${s.substring(0, 4)}-${s.substring(4, 6)}-${s.substring(6, 8)}'
          'T${s.substring(8, 10)}:${s.substring(10, 12)}:${s.substring(
          12, 14)}',
    );
  } else {
    return null;
  }
}

String dateTimeToString(DateTime dt) {
  return dateTimeToInt(dt).toString();
}

final percentFormat = NumberFormat.decimalPattern('de_DE')
  ..minimumFractionDigits = 1
  ..maximumFractionDigits = 1;

String formatPercent(double value) {
  return '${percentFormat.format(value * 100)} %';
}

String formatCurrency(double value) {
  return _currencyFormat.format(value);
}

String getAssetTypeName(AppLocalizations l10n, AssetTypes type, {bool plural = false}) {
  return switch ((type, plural)) {
    (AssetTypes.stock, false) => l10n.stock,
    (AssetTypes.stock, true) => l10n.stocks,
    (AssetTypes.crypto, false) => l10n.crypto,
    (AssetTypes.crypto, true) => l10n.cryptos,
    (AssetTypes.etf, false) => l10n.etf,
    (AssetTypes.etf, true) => l10n.etfs,
    (AssetTypes.fund, false) => l10n.fund,
    (AssetTypes.fund, true) => l10n.funds,
    (AssetTypes.fiat, false) => l10n.fiat,
    (AssetTypes.fiat, true) => l10n.fiats,
    (AssetTypes.derivative, false) => l10n.derivative,
    (AssetTypes.derivative, true) => l10n.derivatives,
  };
}
