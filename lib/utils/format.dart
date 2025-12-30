import 'package:intl/intl.dart';

final dateFormat = DateFormat('dd.MM.yyyy');
final dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm');

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

