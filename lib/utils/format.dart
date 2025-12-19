import 'package:intl/intl.dart';

int dateTimeToInt(DateTime datetime) {
  return int.parse(DateFormat('yyyyMMdd').format(datetime));
}

String dateTimeToString(DateTime datetime) {
  return dateTimeToInt(datetime).toString();
}