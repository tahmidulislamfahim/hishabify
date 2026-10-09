import 'package:intl/intl.dart';

class AppFormatters {
  static String formatCurrency(double amount, {String currency = '\$'}) {
    final formatter = NumberFormat("#,##0.##", "en_US");
    // Show clean string: "$ 500" or "$ 500.50"
    final formattedNumber = formatter.format(amount.abs());
    return '$currency $formattedNumber';
  }

  static String formatDate(DateTime dateTime, {String format = 'dd MMM yyyy'}) {
    try {
      return DateFormat(format).format(dateTime);
    } catch (_) {
      return DateFormat('dd MMM yyyy').format(dateTime);
    }
  }

  static String formatTime(DateTime dateTime, {String format = 'hh:mm a'}) {
    try {
      return DateFormat(format).format(dateTime);
    } catch (_) {
      return DateFormat('hh:mm a').format(dateTime);
    }
  }

  static String formatDateTime(
    DateTime dateTime, {
    String dateFormat = 'dd MMM yyyy',
    String timeFormat = 'hh:mm a',
  }) {
    return '${formatDate(dateTime, format: dateFormat)} - ${formatTime(dateTime, format: timeFormat)}';
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} kb';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
