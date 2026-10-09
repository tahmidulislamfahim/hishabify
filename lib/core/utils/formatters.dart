import 'package:intl/intl.dart';

class AppFormatters {
  static String formatCurrency(double amount, {String currency = '\$'}) {
    final formatter = NumberFormat("#,##0.##", "en_US");
    // Show clean string: "$ 500" or "$ 500.50"
    final formattedNumber = formatter.format(amount.abs());
    return '$currency $formattedNumber';
  }

  /// Returns a clean currency symbol/code guaranteed to be compatible with PDF fonts
  /// (avoiding tofu / cross-mark glyphs like '☒' for ৳, ₹, €, etc.).
  static String getPdfSafeCurrency(String currency) {
    final trimmed = currency.trim();
    switch (trimmed) {
      case '৳':
        return 'Tk';
      case '₹':
        return 'Rs';
      case '€':
        return 'EUR';
      case '£':
        return 'GBP';
      case '¥':
        return 'JPY';
      case '\$':
        return '\$';
      case 'AED':
        return 'AED';
      case 'SAR':
        return 'SAR';
      case 'PKR':
        return 'PKR';
      case 'CAD':
        return 'CAD';
      case 'AUD':
        return 'AUD';
      default:
        var safe = trimmed
            .replaceAll('৳', 'Tk')
            .replaceAll('₹', 'Rs')
            .replaceAll('€', 'EUR')
            .replaceAll('£', 'GBP')
            .replaceAll('¥', 'JPY');
        return safe.isEmpty ? '\$' : safe;
    }
  }

  /// Formats currency specifically for PDF documents to prevent cross markings (☒).
  static String formatPdfCurrency(double amount, {String currency = '\$'}) {
    return formatCurrency(amount, currency: getPdfSafeCurrency(currency));
  }

  /// Sanitizes text strings for PDF rendering by removing unsupported emojis
  /// and control characters that trigger cross-mark glyphs (☒).
  static String sanitizeForPdf(String? text, {String fallback = '-'}) {
    if (text == null || text.trim().isEmpty) return fallback;
    final emojiRegex = RegExp(
      r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F700}-\u{1F77F}\u{1F780}-\u{1F7FF}\u{1F800}-\u{1F8FF}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}\u{1FA70}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
      unicode: true,
    );
    final cleaned = text.replaceAll(emojiRegex, '').trim();
    return cleaned.isEmpty ? fallback : cleaned;
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
