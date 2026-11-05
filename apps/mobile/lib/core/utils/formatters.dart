import 'package:intl/intl.dart';

final _rupiah = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

final _date = DateFormat('d MMM yyyy', 'id_ID');
final _time = DateFormat('HH:mm', 'id_ID');
final _dateTime = DateFormat('d MMM yyyy · HH:mm', 'id_ID');

String formatRupiah(int value) => _rupiah.format(value);

String formatDate(DateTime? value) => value == null ? '-' : _date.format(value);

String formatTime(DateTime? value) => value == null ? '-' : _time.format(value);

String formatDateTime(DateTime? value) =>
    value == null ? '-' : _dateTime.format(value);

String timeAgo(DateTime? value) {
  if (value == null) return '-';
  final diff = DateTime.now().difference(value);
  if (diff.inSeconds < 60) return 'baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inDays < 7) return '${diff.inDays} hari lalu';
  return formatDate(value);
}

String formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  return '${(meters / 1000).toStringAsFixed(1)} km';
}
