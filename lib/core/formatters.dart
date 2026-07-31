import 'package:intl/intl.dart';

final _idrFormat = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

String formatIdr(num amount) => _idrFormat.format(amount);

/// Formats a [DateTime] into a localized date string (e.g. "31 Juli 2026").
String formatLocalDate(DateTime date, [String locale = 'id']) {
  final fmt = DateFormat.yMMMMd(locale);
  return fmt.format(date);
}
