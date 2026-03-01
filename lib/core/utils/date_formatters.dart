import 'package:intl/intl.dart';

abstract final class DateFormatters {
  static final _dateFull = DateFormat('dd/MM/yyyy');
  static final _dateShort = DateFormat('dd/MM');
  static final _time = DateFormat('HH:mm');
  static final _dateTime = DateFormat('dd/MM/yyyy HH:mm');
  static final _dayMonth = DateFormat("d 'de' MMMM", 'pt_BR');

  static String dateFull(DateTime date) => _dateFull.format(date);
  static String dateShort(DateTime date) => _dateShort.format(date);
  static String time(DateTime date) => _time.format(date);
  static String dateTime(DateTime date) => _dateTime.format(date);
  static String dayMonth(DateTime date) => _dayMonth.format(date);

  static String relative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    if (diff.inDays < 7) return 'há ${diff.inDays}d';
    return dateFull(date);
  }
}
