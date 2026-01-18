import 'package:intl/intl.dart';
import 'package:xfin/providers/base_currency_provider.dart';

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
      'T${s.substring(8, 10)}:${s.substring(10, 12)}:${s.substring(12, 14)}',
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
