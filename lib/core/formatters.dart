import 'package:intl/intl.dart';

final _idrFormat = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

String formatIdr(num amount) => _idrFormat.format(amount);
